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

  /// Grouped recommendations — the primary data model
  AiRecommendationSet? _recommendations;
  AiRecommendationSet? get recommendations => _recommendations;

  /// Legacy flat list — kept for the existing itinerary application path
  List<AiSuggestion> _suggestions = [];
  List<AiSuggestion> get suggestions => _suggestions;

  AiGenerationOptions _currentOptions = const AiGenerationOptions();
  AiGenerationOptions get currentOptions => _currentOptions;

  String? _error;
  String? get error => _error;

  // ── Computed helpers ───────────────────────────────────────────────────────

  /// All suggestions across all sections (landmarks + gems + food)
  List<AiSuggestion> get allSuggestions =>
      _recommendations?.allSuggestions ?? _suggestions;

  /// Accepted items across all sections
  List<AiSuggestion> get acceptedSuggestions =>
      allSuggestions.where((s) => s.isAccepted).toList();

  int get acceptedCount => acceptedSuggestions.length;

  // ── Primary: Grouped Recommendation Generation ────────────────────────────

  /// Generates the three-section recommendation set (main flow).
  Future<void> generateRecommendations({
    required Trip trip,
    required AiGenerationOptions options,
  }) async {
    if (_isGenerating) return;
    _isGenerating = true;

    _status = AiGenerationStatus.loading;
    _recommendations = null;
    _suggestions = [];
    _error = null;
    _currentOptions = options;
    notifyListeners();

    try {
      _visitedRegistry.clear();
      _visitedRegistry.seedFromTrips(_tripProvider.trips);
      _visitedRegistry.seedFromPreferences(_prefs);

      final result = await _aiService.generateRecommendations(
        trip: trip,
        options: options,
      );

      _recommendations = result;
      _status = AiGenerationStatus.ready;
    } catch (e) {
      _status = AiGenerationStatus.error;
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ── Legacy: Flat Itinerary Generation ─────────────────────────────────────

  Future<void> generateDailyItinerary({
    required Trip trip,
    required int dayIndex,
    AiGenerationOptions? options,
    RegenerationStyle? style,
  }) async {
    if (_isGenerating) return;
    _isGenerating = true;

    _status = AiGenerationStatus.loading;
    _suggestions = [];
    _recommendations = null;
    _error = null;
    if (options != null) _currentOptions = options;
    notifyListeners();

    try {
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

  Future<void> generateTripItinerary({
    required Trip trip,
    AiGenerationOptions? options,
  }) async {
    if (_isGenerating) return;
    _isGenerating = true;

    _status = AiGenerationStatus.loading;
    _suggestions = [];
    _recommendations = null;
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

  // ── Accept / Reject (works across all sections) ───────────────────────────

  void toggleAccept(String id) {
    bool found = false;
    if (_recommendations != null) {
      for (final section in [
        _recommendations!.landmarks,
        _recommendations!.localGems,
        _recommendations!.food,
      ]) {
        final idx = section.indexWhere((s) => s.id == id);
        if (idx != -1) {
          section[idx].isAccepted = !section[idx].isAccepted;
          if (section[idx].isAccepted) section[idx].isRejected = false;
          found = true;
          break;
        }
      }
    }
    if (!found) {
      final idx = _suggestions.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _suggestions[idx].isAccepted = !_suggestions[idx].isAccepted;
        if (_suggestions[idx].isAccepted) _suggestions[idx].isRejected = false;
      }
    }
    notifyListeners();
  }

  void toggleReject(String id) {
    bool found = false;
    if (_recommendations != null) {
      for (final section in [
        _recommendations!.landmarks,
        _recommendations!.localGems,
        _recommendations!.food,
      ]) {
        final idx = section.indexWhere((s) => s.id == id);
        if (idx != -1) {
          section[idx].isRejected = !section[idx].isRejected;
          if (section[idx].isRejected) section[idx].isAccepted = false;
          found = true;
          break;
        }
      }
    }
    if (!found) {
      final idx = _suggestions.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _suggestions[idx].isRejected = !_suggestions[idx].isRejected;
        if (_suggestions[idx].isRejected) _suggestions[idx].isAccepted = false;
      }
    }
    notifyListeners();
  }

  // ── Apply to Itinerary ────────────────────────────────────────────────────

  Future<void> applyToItinerary(Trip trip, int dayIndex) async {
    _status = AiGenerationStatus.applying;
    notifyListeners();

    final accepted = acceptedSuggestions;
    if (accepted.isEmpty) {
      _status = AiGenerationStatus.done;
      notifyListeners();
      return;
    }

    try {
      // Simulate slightly longer loading for the UI transition
      // so the user sees the "Scheduling..." steps.
      await Future.delayed(const Duration(seconds: 3));

      final scheduled = await _aiService.scheduleSelectedSuggestions(
        selections: accepted,
        trip: trip,
        dayIndex: dayIndex,
      );

      _prefs.recordAccepted(accepted);
      final rejected =
          allSuggestions.where((s) => s.isRejected).toList();
      _prefs.recordRejected(rejected);
      await _prefs.save(_tripProvider.userId ?? '');

      for (final s in scheduled) {
        final activity = Activity(
          id: DateTime.now().millisecondsSinceEpoch.toString() + s.id,
          title: s.name,
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
    } catch (e) {
      _status = AiGenerationStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _isGenerating = false;
    _status = AiGenerationStatus.idle;
    _suggestions = [];
    _recommendations = null;
    _error = null;
    notifyListeners();
  }
}
