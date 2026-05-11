import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/ai_models.dart';
import '../models/models.dart';
import 'ai/gap_filler.dart';
import 'ai/opening_hours_validator.dart';
import 'ai/optimization_engine.dart';
import 'ai/real_place_discovery_service.dart';
import 'ai/time_budget_validator.dart';
import 'user_preference_service.dart';
import 'visited_places_registry.dart';

/// The core AI Travel Assistant engine.
///
/// This service orchestrates the generation pipeline:
/// 1. Data Fetching  → RealPlaceDiscoveryService (Google Places API)
/// 2. Filtering      → Cross-trip memory, rejected types, toggle-based
/// 3. Ranking        → OptimizationEngine.rankSections per section
/// 4. Validation     → Time Budget, Opening Hours (for itinerary mode)
/// 5. Enhancement    → Gap Filler, Confidence Labels, Spontaneity trim
class AiTripService {
  final UserPreferenceService _prefs;
  final VisitedPlacesRegistry _visitedRegistry;
  final RealPlaceDiscoveryService _discoveryService;

  AiTripService(
    this._prefs,
    this._visitedRegistry,
    this._discoveryService,
  );

  // ── Primary: Grouped Recommendations ─────────────────────────────────────

  /// Generates a grouped [AiRecommendationSet] driven by [options].
  /// Results are split into Landmarks, Local Gems, and Food sections,
  /// each sorted by recommendation score descending.
  Future<AiRecommendationSet> generateRecommendations({
    required Trip trip,
    required AiGenerationOptions options,
  }) async {
    final city = trip.city ?? trip.country;
    debugPrint('AI: Generating grouped recommendations for $city — style=${options.explorationStyle.name}');

    // 1. Fetch real places via Google Places API (grouped by section)
    final rawSet = await _discoveryService.fetchGroupedPlaces(trip, options);
    debugPrint('AI: Fetched — landmarks=${rawSet.landmarks.length}, gems=${rawSet.localGems.length}, food=${rawSet.food.length}');

    // 2. Filter each section: visited registry + toggle hard-filters
    final filteredLandmarks = _filterSection(
      rawSet.landmarks,
      options: options,
    );
    final filteredGems = options.localGems
        ? _filterSection(rawSet.localGems, options: options)
        : <AiSuggestion>[];
    final filteredFood = (options.includeRestaurants || options.includeCafes)
        ? _filterSection(rawSet.food, options: options)
        : <AiSuggestion>[];

    debugPrint('AI: After filtering — landmarks=${filteredLandmarks.length}, gems=${filteredGems.length}, food=${filteredFood.length}');

    final filteredSet = AiRecommendationSet(
      landmarks: filteredLandmarks,
      localGems: filteredGems,
      food: filteredFood,
    );

    // 3. Rank each section independently
    final rankedSet = OptimizationEngine.rankSections(
      set: filteredSet,
      options: options,
    );

    debugPrint('AI: Final — landmarks=${rankedSet.landmarks.length}, gems=${rankedSet.localGems.length}, food=${rankedSet.food.length}');
    return rankedSet;
  }

  // ── Section Filtering ─────────────────────────────────────────────────────

  List<AiSuggestion> _filterSection(
    List<AiSuggestion> suggestions, {
    required AiGenerationOptions options,
  }) {
    return suggestions.where((s) {
      final id = s.placeId ?? s.id;

      // Cross-trip memory
      if (_visitedRegistry.isVisited(id)) return false;
      if (_visitedRegistry.isVisitedByTitle(s.name)) return false;

      // Rejected types
      if (s.types.any((t) => _prefs.shouldAvoidType(t))) return false;

      // Food toggles
      if (!options.includeRestaurants && s.category == 'Restaurant') return false;
      if (!options.includeCafes && s.category == 'Cafe') return false;

      // Family friendly: exclude adult venues
      if (options.familyFriendly) {
        const adultCategories = {'Bar', 'Night Club', 'Casino'};
        if (adultCategories.contains(s.category)) return false;
      }

      return true;
    }).toList();
  }

  // ── Legacy: Flat Itinerary Generation ────────────────────────────────────

  /// Generates a list of suggested activities for a specific trip and day.
  /// Uses the new grouped discovery pipeline internally but flattens the result
  /// for the existing itinerary flow.
  Future<List<AiSuggestion>> generateDailyItinerary({
    required Trip trip,
    required int dayIndex,
    required AiGenerationOptions options,
    RegenerationStyle? style,
    String? anchorTime,
  }) async {
    final city = trip.city ?? trip.country;
    debugPrint('AI: Generating flat itinerary for $city, Day $dayIndex');

    // Use the new grouped pipeline
    final rawSet = await _discoveryService.fetchGroupedPlaces(trip, options);
    final rawPlaces = rawSet.allSuggestions;

    // Filter
    final filtered = rawPlaces.where((s) {
      final id = s.placeId ?? s.id;
      if (_visitedRegistry.isVisited(id)) return false;
      if (_visitedRegistry.isVisitedByTitle(s.name)) return false;
      if (s.types.any((t) => _prefs.shouldAvoidType(t))) return false;
      if (!options.includeRestaurants && s.category == 'Restaurant') return false;
      if (!options.includeCafes && s.category == 'Cafe') return false;
      if (options.familyFriendly) {
        if (!(s.types.any((t) => const {
              'park', 'museum', 'tourist_attraction', 'amusement_park',
              'zoo', 'aquarium', 'natural_feature', 'restaurant',
            }.contains(t)))) {
          return s.types.isEmpty;
        }
      }
      if (!options.focusPopular) {
        if (s.types.length == 1 &&
            s.types.first == 'point_of_interest' &&
            s.popularityScore < 4.5) {
          return false;
        }
      }
      return true;
    }).toList();

    debugPrint('AI: ${filtered.length} candidates after filtering');

    // Rank
    double? anchorLat;
    double? anchorLng;

    final currentDay = trip.days.firstWhere(
      (d) => d.dayIndex == dayIndex,
      orElse: () => trip.days.isNotEmpty
          ? trip.days[0]
          : TripDay(dayIndex: dayIndex, date: DateTime.now()),
    );

    if (currentDay.activities.isNotEmpty) {
      final last = currentDay.activities.last;
      anchorLat = last.lat;
      anchorLng = last.lng;
    }

    var optimized = OptimizationEngine.rank(
      suggestions: filtered,
      categoryWeights: _prefs.getWeightedCategoryScores(),
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      options: options,
    );

    if (style != null) {
      optimized = _applyStyle(optimized, style);
    }

    // Validate time budget
    final budgetResult = TimeBudgetValidator.validate(
      optimized,
      dayStartTime: anchorTime ?? '09:00',
    );
    var validated = budgetResult.suggestions;

    if (options.leaveFreetime && validated.length > 3) {
      validated = validated.take(3).toList();
    }

    if (options.explorationStyle == ExplorationStyle.outsideCity &&
        validated.length > 4) {
      validated = validated.take(4).toList();
    }

    validated = GapFiller.fill(
      suggestions: validated,
      dayStartTime: anchorTime ?? '09:00',
      anchorLat: anchorLat,
      anchorLng: anchorLng,
    );

    final withHours = OpeningHoursValidator.validate(validated);
    final finalResult = ConfidenceLabelAssigner.assignAll(
      suggestions: withHours,
      categoryWeights: _prefs.getWeightedCategoryScores(),
    );

    return finalResult;
  }

  // ── Styles ────────────────────────────────────────────────────────────────

  List<AiSuggestion> _applyStyle(
      List<AiSuggestion> list, RegenerationStyle style) {
    switch (style) {
      case RegenerationStyle.different:
        return list.reversed.toList();
      case RegenerationStyle.moreRelaxed:
        return list.where((s) => s.estimatedDuration <= 60).toList();
      case RegenerationStyle.moreLocal:
        return list.where((s) => s.popularityScore < 4.5).toList();
      case RegenerationStyle.morePopular:
        return list
          ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    }
  }

  /// Takes a list of user-selected suggestions and schedules them into a time-aware day
  Future<List<AiSuggestion>> scheduleSelectedSuggestions({
    required List<AiSuggestion> selections,
    required Trip trip,
    required int dayIndex,
    String? anchorTime,
  }) async {
    debugPrint('AI: Scheduling ${selections.length} selected suggestions for Day $dayIndex');

    double? anchorLat;
    double? anchorLng;

    final currentDay = trip.days.firstWhere(
      (d) => d.dayIndex == dayIndex,
      orElse: () => trip.days.isNotEmpty
          ? trip.days[0]
          : TripDay(dayIndex: dayIndex, date: DateTime.now()),
    );

    if (currentDay.activities.isNotEmpty) {
      final last = currentDay.activities.last;
      anchorLat = last.lat;
      anchorLng = last.lng;
    }

    // 1. Rank & order geographically based on anchor
    var optimized = OptimizationEngine.rank(
      suggestions: selections,
      categoryWeights: _prefs.getWeightedCategoryScores(),
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      options: const AiGenerationOptions(),
    );

    // 2. Assign time blocks and validate time budget
    final budgetResult = TimeBudgetValidator.validate(
      optimized,
      dayStartTime: anchorTime ?? '09:00',
    );
    var validated = budgetResult.suggestions;

    // 3. Fill gaps (meals, transit)
    validated = GapFiller.fill(
      suggestions: validated,
      dayStartTime: anchorTime ?? '09:00',
      anchorLat: anchorLat,
      anchorLng: anchorLng,
    );

    // 4. Validate opening hours
    final withHours = OpeningHoursValidator.validate(validated);

    return withHours;
  }

  // ignore: unused_element
  AiSuggestion _mapToSuggestion(Map<String, dynamic> p) {
    return AiSuggestion(
      id: p['placeId'] ?? Random().nextInt(99999).toString(),
      name: p['name'],
      category: p['category'],
      imageUrl: p['imageUrl'],
      lat: p['lat'],
      lng: p['lng'],
      address: p['address'],
      placeId: p['placeId'],
      estimatedDuration: p['duration'] ?? 90,
      explanation: p['explanation'] ?? 'Highly rated among travelers like you.',
      popularityScore: (p['popularity'] as num?)?.toDouble() ?? 4.0,
      userRatingsTotal: (p['userRatingsTotal'] as num?)?.toInt() ?? 0,
      types: List<String>.from(p['types'] ?? []),
      confidence: AiConfidence.greatMatch,
      isLocalGem: p['isLocalGem'] as bool? ?? false,
    );
  }
}
