import 'package:flutter/material.dart';
import '../models/ai_models.dart';
import '../models/models.dart';
import '../services/ai_trip_service.dart';
import '../services/user_preference_service.dart';
import '../services/visited_places_registry.dart';
import 'trip_provider.dart';

class AiProvider extends ChangeNotifier {
  final AiTripService _aiService;
  final UserPreferenceService _prefs;
  final TripProvider _tripProvider;
  final VisitedPlacesRegistry _visitedRegistry;

  AiProvider(this._aiService, this._prefs, this._tripProvider, this._visitedRegistry);

  // Guard against duplicate concurrent generation calls
  bool _isGenerating = false;

  AiGenerationStatus _status = AiGenerationStatus.idle;
  AiGenerationStatus get status => _status;

  List<AiSuggestion> _suggestions = [];
  List<AiSuggestion> get suggestions => _suggestions;

  AiDayBudget? _currentBudget;
  AiDayBudget? get currentBudget => _currentBudget;

  AiGenerationOptions _currentOptions = const AiGenerationOptions();
  AiGenerationOptions get currentOptions => _currentOptions;

  String? _error;
  String? get error => _error;

  // -------------------------------------------------------------------------
  // Generation
  // -------------------------------------------------------------------------

  Future<void> generateDailyItinerary({
    required Trip trip,
    required int dayIndex,
    AiGenerationOptions? options,
    RegenerationStyle? style,
  }) async {
    // Prevent duplicate concurrent calls
    if (_isGenerating) return;
    _isGenerating = true;

    _status = AiGenerationStatus.loading;
    _suggestions = [];
    _error = null;
    if (options != null) _currentOptions = options;
    notifyListeners();

    try {
      // Clear and re-seed registry to ensure fresh state for this attempt
      _visitedRegistry.clear();
      _visitedRegistry.seedFromTrips(_tripProvider.trips);
      _visitedRegistry.seedFromPreferences(_prefs);

      final result = await _aiService.generateDailyItinerary(
        trip: trip,
        dayIndex: dayIndex,
        options: _currentOptions,
        style: style,
      );

      _suggestions = result;
      _status = AiGenerationStatus.ready;
    } catch (e) {
      _status = AiGenerationStatus.error;
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Generates suggestions across ALL days of a trip.
  /// Merges all days into a single flat list of [AiSuggestion] with dayIndex set.
  Future<void> generateTripItinerary({
    required Trip trip,
    AiGenerationOptions? options,
  }) async {
    if (_isGenerating) return;
    _isGenerating = true;

    _status = AiGenerationStatus.loading;
    _suggestions = [];
    _error = null;
    if (options != null) _currentOptions = options;
    notifyListeners();

    try {
      _visitedRegistry.clear();
      _visitedRegistry.seedFromTrips(_tripProvider.trips);
      _visitedRegistry.seedFromPreferences(_prefs);

      final allSuggestions = <AiSuggestion>[];

      final days = trip.days.isNotEmpty
          ? trip.days
          : List.generate(
              trip.durationDays,
              (i) => TripDay(
                dayIndex: i + 1,
                date: trip.startDate.add(Duration(days: i)),
              ),
            );

      for (final day in days) {
        final daySuggestions = await _aiService.generateDailyItinerary(
          trip: trip,
          dayIndex: day.dayIndex,
          options: _currentOptions,
        );
        // Tag each suggestion with its day
        allSuggestions.addAll(
          daySuggestions.map((s) => s.copyWith(dayIndex: day.dayIndex)),
        );
      }

      _suggestions = allSuggestions;
      _status = AiGenerationStatus.ready;
    } catch (e) {
      _status = AiGenerationStatus.error;
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  void toggleAccept(String id) {
    final idx = _suggestions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _suggestions[idx].isAccepted = !_suggestions[idx].isAccepted;
      if (_suggestions[idx].isAccepted) _suggestions[idx].isRejected = false;
      notifyListeners();
    }
  }

  void toggleReject(String id) {
    final idx = _suggestions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _suggestions[idx].isRejected = !_suggestions[idx].isRejected;
      if (_suggestions[idx].isRejected) _suggestions[idx].isAccepted = false;
      notifyListeners();
    }
  }

  /// Applies accepted suggestions to the actual trip itinerary.
  Future<void> applyToItinerary(Trip trip, int dayIndex) async {
    _status = AiGenerationStatus.applying;
    notifyListeners();

    final accepted = _suggestions.where((s) => s.isAccepted).toList();
    if (accepted.isEmpty) {
      _status = AiGenerationStatus.done;
      notifyListeners();
      return;
    }

    // Record for learning
    _prefs.recordAccepted(accepted);
    final rejected = _suggestions.where((s) => s.isRejected).toList();
    _prefs.recordRejected(rejected);
    await _prefs.save(_tripProvider.userId ?? '');

    // Convert to TripActivities and add to provider
    for (final s in accepted) {
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString() + s.id,
        title: s.name,
        // category is not directly in Activity but we can pass it to notes or types if needed, 
        // but here it seems the user meant to use the Activity model
        lat: s.lat,
        lng: s.lng,
        address: s.address ?? '',
        placeId: s.placeId,
        source: 'ai',
        imageUrl: s.imageUrl,
        startTime: s.recommendedArrivalTime ?? '09:00',
        duration: s.estimatedDuration,
      );
      await _tripProvider.addActivity(trip.id, dayIndex, activity);
    }

    _status = AiGenerationStatus.done;
    notifyListeners();
  }

  void reset() {
    _isGenerating = false;
    _status = AiGenerationStatus.idle;
    _suggestions = [];
    _error = null;
    notifyListeners();
  }
}
