import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/mock_data_service.dart';
import '../services/places_service.dart';

class TripProvider extends ChangeNotifier {
  final _placesService = PlacesService();

  // --- Trips List ---
  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Future<void> fetchTrips() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _trips = await SupabaseService.getTrips();
    notifyListeners();
  }

  // --- Wizard State ---
  Trip? _draftTrip;
  int _currentStep = 0;
  String? _lastError;

  Trip? get draftTrip => _draftTrip;
  int get currentStep => _currentStep;
  String? get lastError => _lastError;

  void startNewTrip() {
    final userId = SupabaseService.currentUser?.id ?? 'guest';
    _draftTrip = Trip(
      id: '',
      userId: userId,
      name: '',
      country: '',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      days: [],
    );
    _currentStep = 0;
    notifyListeners();
  }

  void updateDraft(Trip updatedTrip) {
    // If country changed, reset city
    if (_draftTrip != null && _draftTrip!.country != updatedTrip.country) {
      _draftTrip = updatedTrip.copyWith(city: '');
    } else {
      _draftTrip = updatedTrip;
    }
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void setAdults(int count) {
    if (_draftTrip == null) return;
    final breakdown = Map<String, int>.from(_draftTrip!.travelersBreakdown);
    breakdown['adults'] = count;
    _draftTrip = _draftTrip!.copyWith(
      travelersBreakdown: breakdown,
      travelersCount: count + (breakdown['children'] ?? 0),
    );
    notifyListeners();
  }

  void setChildren(int count) {
    if (_draftTrip == null) return;
    final breakdown = Map<String, int>.from(_draftTrip!.travelersBreakdown);
    breakdown['children'] = count;
    _draftTrip = _draftTrip!.copyWith(
      travelersBreakdown: breakdown,
      travelersCount: (breakdown['adults'] ?? 1) + count,
    );
    notifyListeners();
  }

  Future<bool> saveTrip() async {
    print('***** TripProvider: saveTrip() called');
    final draft = _draftTrip;
    final userId = SupabaseService.currentUser?.id;
    
    if (draft == null) {
      print('***** saveTrip FAILED: draftTrip is null');
      return false;
    }
    if (userId == null) {
      print('***** saveTrip FAILED: No authenticated user found. Current user: ${SupabaseService.currentUser}');
      return false;
    }

    print('***** saveTrip: Proceeding with userId=$userId, draftName=${draft.name}');

    // Use city name for trip name if empty
    final finalName = draft.name.trim().isEmpty
        ? '${draft.city?.isNotEmpty == true ? draft.city : draft.country} Trip'
        : draft.name;

    // Fetch dynamic image if not already set (e.g. from Google Places)
    final imageUrl = draft.coverImageUrl ??
        MockDataService.getDestinationImage(draft.city, draft.country);

    // Generate days automatically
    final generatedDays = _generateDays(draft.startDate, draft.endDate);

    final newTrip = draft.copyWith(
      userId: userId,
      name: finalName,
      coverImageUrl: imageUrl,
      days: generatedDays,
      updatedAt: DateTime.now(),
    );

    try {
      _lastError = null;
      final savedTrip = await SupabaseService.createTrip(newTrip);
      _trips.insert(0, savedTrip);
      _draftTrip = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving trip: $e');
      _lastError = e.toString();
      if (e is PostgrestException) {
        debugPrint('Postgrest Error Details: ${e.message}, Code: ${e.code}');
        _lastError = 'Database Error: ${e.message}';
      }
      notifyListeners();
      return false;
    }
  }

  List<TripDay> _generateDays(DateTime start, DateTime end) {
    List<TripDay> days = [];
    final duration = end.difference(start).inDays + 1;
    for (int i = 0; i < duration; i++) {
      days.add(TripDay(
        dayIndex: i + 1,
        date: start.add(Duration(days: i)),
        activities: [],
      ));
    }
    return days;
  }

  // --- Itinerary Management ---

  void addActivity(String tripId, int dayIndex, Activity activity) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);

    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = updatedDays[dayIdx];
    final updatedActivities = List<Activity>.from(day.activities)
      ..add(activity);

    updatedDays[dayIdx] = day.copyWith(activities: updatedActivities);

    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();

    // Trigger real-time calculation immediately
    updateActivityTransportAuto(
        tripId, dayIndex, activity.id, TravelMode.driving);
  }

  void deleteActivity(String tripId, int dayIndex, String activityId) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);

    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = updatedDays[dayIdx];
    final updatedActivities = List<Activity>.from(day.activities)
      ..removeWhere((a) => a.id == activityId);

    updatedDays[dayIdx] = day.copyWith(activities: updatedActivities);

    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();
  }

  void reorderActivities(
      String tripId, int dayIndex, int oldIndex, int newIndex) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);

    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = updatedDays[dayIdx];
    final updatedActivities = List<Activity>.from(day.activities);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Activity item = updatedActivities.removeAt(oldIndex);
    updatedActivities.insert(newIndex, item);

    updatedDays[dayIdx] = day.copyWith(activities: updatedActivities);

    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();
  }

  void updateDayStartTime(String tripId, int dayIndex, String startTime) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);
    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    updatedDays[dayIdx] = updatedDays[dayIdx].copyWith(startTime: startTime);
    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();
  }

  void updateActivityTransport(String tripId, int dayIndex, String activityId,
      TravelMode mode, int duration) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);
    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = updatedDays[dayIdx];
    final updatedActivities = day.activities.map((a) {
      if (a.id == activityId) {
        return a.copyWith(
          transportModeFromPrevious: mode,
          travelDurationFromPrevious: duration,
        );
      }
      return a;
    }).toList();

    updatedDays[dayIdx] = day.copyWith(activities: updatedActivities);
    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();
  }

  Future<void> updateActivityTransportAuto(
      String tripId, int dayIndex, String activityId, TravelMode mode) async {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final dayIdx = trip.days.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = trip.days[dayIdx];
    final activityIndex = day.activities.indexWhere((a) => a.id == activityId);
    if (activityIndex <= 0) return;

    final currentActivity = day.activities[activityIndex];
    final previousActivity = day.activities[activityIndex - 1];

    int finalDuration = 15; // Default fallback

    if (currentActivity.lat != null &&
        currentActivity.lng != null &&
        previousActivity.lat != null &&
        previousActivity.lng != null) {
      try {
        final result = await _placesService.getDistanceAndDuration(
            previousActivity.lat!,
            previousActivity.lng!,
            currentActivity.lat!,
            currentActivity.lng!,
            mode.name);

        if (result != null) {
          finalDuration = (result['duration'] / 60).ceil();
        } else {
          // Robust Fallback: Calculate distance and estimate time based on mode
          final distanceKm = _calculateDistance(
              previousActivity.lat!,
              previousActivity.lng!,
              currentActivity.lat!,
              currentActivity.lng!);

          finalDuration = _estimateDuration(distanceKm, mode);
        }
      } catch (e) {
        print('Error in auto transport calculation: $e');
        finalDuration = 20; // Another fallback
      }
    }

    updateActivityTransport(tripId, dayIndex, activityId, mode, finalDuration);
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance for estimation (not Haversine but enough for UI feedback)
    // 1 degree is roughly 111km
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return (dLat + dLon) * 111.0;
  }

  int _estimateDuration(double distanceKm, TravelMode mode) {
    double speedKmh = 50.0; // driving
    switch (mode) {
      case TravelMode.walking:
        speedKmh = 5.0;
        break;
      case TravelMode.driving:
        speedKmh = 60.0;
        break;
      case TravelMode.transit:
        speedKmh = 25.0;
        break;
      case TravelMode.flight:
        speedKmh = 800.0;
        break;
    }

    // time = distance / speed * 60 minutes
    // add 5 minutes for "overhead" (parking, waiting, etc)
    return ((distanceKm / speedKmh) * 60).ceil() + 5;
  }

  void updateActivityDuration(
      String tripId, int dayIndex, String activityId, int duration) {
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = _trips[tripIndex];
    final updatedDays = List<TripDay>.from(trip.days);
    final dayIdx = updatedDays.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return;

    final day = updatedDays[dayIdx];
    final updatedActivities = day.activities.map((a) {
      if (a.id == activityId) {
        return a.copyWith(duration: duration);
      }
      return a;
    }).toList();

    updatedDays[dayIdx] = day.copyWith(activities: updatedActivities);
    _trips[tripIndex] =
        trip.copyWith(days: updatedDays, updatedAt: DateTime.now());
    notifyListeners();
  }
}
