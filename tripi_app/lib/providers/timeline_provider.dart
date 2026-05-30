import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/timeline_models.dart';
import '../services/timeline/timeline_orchestrator.dart';
import '../services/timeline/timeline_recommendation_service.dart';
import '../services/timeline/travel_context_service.dart';

class TimelineProvider extends ChangeNotifier {
  final TimelineOrchestratorService _orchestrator =
      TimelineOrchestratorService();
  final TimelineRecommendationService _recommendationService =
      TimelineRecommendationService();
  final TravelContextService _travelContextService = TravelContextService();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DestinationInsight? _selectedInsight;

  TravelIntent _travelIntent = const TravelIntent();

  List<DestinationInsight> _recommendedInsights = [];
  bool _isLoadingInsights = false;
  bool _isLoadingTravelContext = false;
  bool _hasLoadedTravelContext = false;
  bool _hasShownOriginPrompt = false;
  bool _pendingRecommendationAfterContextLoad = false;

  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  DestinationInsight? get selectedInsight => _selectedInsight;
  TravelIntent get travelIntent => _travelIntent;
  List<DestinationInsight> get recommendedInsights => _recommendedInsights;
  bool get isLoadingInsights => _isLoadingInsights;
  bool get isLoadingTravelContext => _isLoadingTravelContext;
  bool get hasLoadedTravelContext => _hasLoadedTravelContext;
  bool get shouldShowOriginPrompt =>
      _hasLoadedTravelContext &&
      !_hasShownOriginPrompt &&
      hasValidSelectedRange &&
      _travelIntent.originAirport == null;

  bool get hasSelectedRange =>
      _selectedStartDate != null && _selectedEndDate != null;
  bool get hasValidSelectedRange =>
      _selectedStartDate != null &&
      _selectedEndDate != null &&
      !_selectedEndDate!.isBefore(_selectedStartDate!);
  int? get selectedDurationDays {
    if (!hasValidSelectedRange) return null;
    return _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
  }

  Future<void> loadTravelContext() async {
    if (_isLoadingTravelContext || _hasLoadedTravelContext) return;

    _isLoadingTravelContext = true;
    notifyListeners();

    final savedIntent = await _travelContextService.load();
    if (savedIntent != null) {
      _travelIntent = savedIntent;
    }

    _isLoadingTravelContext = false;
    _hasLoadedTravelContext = true;
    notifyListeners();

    if (_pendingRecommendationAfterContextLoad || hasValidSelectedRange) {
      _pendingRecommendationAfterContextLoad = false;
      await _generateRecommendations();
    }
  }

  void markOriginPromptShown() {
    _hasShownOriginPrompt = true;
  }

  Future<void> updateTravelIntent(
    TravelIntent newIntent, {
    bool clearOrigin = false,
  }) async {
    _travelIntent = newIntent.normalized();
    _selectedInsight = null;
    _travelContextService.save(_travelIntent, clearOrigin: clearOrigin);
    if (hasValidSelectedRange) {
      if (!_hasLoadedTravelContext) {
        _pendingRecommendationAfterContextLoad = true;
        notifyListeners();
      } else {
        _generateRecommendations();
      }
    } else {
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    if (_selectedStartDate == null) {
      _selectedStartDate = date;
      _selectedEndDate = null;
    } else if (_selectedEndDate == null) {
      if (date.isBefore(_selectedStartDate!)) {
        // If selecting a date before start date, make it the new start date
        _selectedStartDate = date;
      } else {
        _selectedEndDate = date;
        if (_hasLoadedTravelContext) {
          _generateRecommendations();
        } else {
          _pendingRecommendationAfterContextLoad = true;
        }
      }
    } else {
      // Both are selected, restart selection
      _selectedStartDate = date;
      _selectedEndDate = null;
      _selectedInsight = null;
      _recommendedInsights = [];
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedStartDate = null;
    _selectedEndDate = null;
    _selectedInsight = null;
    _recommendedInsights = [];
    _isLoadingInsights = false;
    notifyListeners();
  }

  void selectDestination(DestinationInsight? insight) {
    _selectedInsight = insight;
    notifyListeners();
  }

  // Generate recommendations based on the selected dates.
  Future<void> _generateRecommendations() async {
    if (!hasValidSelectedRange) return;
    if (!_hasLoadedTravelContext) {
      _pendingRecommendationAfterContextLoad = true;
      notifyListeners();
      return;
    }

    _isLoadingInsights = true;
    _recommendedInsights = [];
    notifyListeners();

    final int month = _selectedStartDate!.month;

    // Use recommendation service to get top destinations for the current intent
    final rankedRecommendations = _recommendationService.rankDestinations(
      intent: _travelIntent,
      month: month,
      selectedStartDate: _selectedStartDate,
      selectedEndDate: _selectedEndDate,
      durationDays: selectedDurationDays,
      limit: 3,
    );

    try {
      final futures = rankedRecommendations
          .map((recommendation) => _orchestrator.getInsights(
                destination: recommendation.destination,
                month: month,
                originCity: _travelIntent.origin,
              ));

      final results = await Future.wait(futures);
      _recommendedInsights = [];
      for (var i = 0; i < results.length; i++) {
        final insight = results[i];
        if (insight == null) continue;
        final recommendation = rankedRecommendations[i];
        _recommendedInsights.add(
          insight.copyWith(
            recommendationScores: {
              ...insight.recommendationScores,
              'score': recommendation.score,
              'reasons': recommendation.reasons,
              'is_fallback': recommendation.isFallback,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching recommended insights: $e');
    } finally {
      _isLoadingInsights = false;
      notifyListeners();
    }
  }

  // Check if selected dates overlap with any existing trips
  Trip? getOverlappingTrip(List<dynamic> trips) {
    if (!hasSelectedRange) return null;

    // Using start of day for comparison
    final start = DateTime(_selectedStartDate!.year, _selectedStartDate!.month,
        _selectedStartDate!.day);
    final end = DateTime(
        _selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day);

    for (final t in trips) {
      if (t is Trip) {
        final tStart =
            DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
        final tEnd = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);

        // Overlap condition: Max(start1, start2) <= Min(end1, end2)
        final maxStart = start.isAfter(tStart) ? start : tStart;
        final minEnd = end.isBefore(tEnd) ? end : tEnd;

        if (!maxStart.isAfter(minEnd)) {
          return t;
        }
      }
    }
    return null;
  }
}
