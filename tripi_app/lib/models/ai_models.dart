/// AI Travel Assistant Data Models
///
/// These models are the shared contract between the AI service pipeline,
/// the provider, and all UI widgets. The pipeline architecture ensures
/// that swapping the mock AI for a real LLM requires no changes here.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Confidence tier for each AI suggestion
enum AiConfidence {
  highlyRecommended, // score 80–100
  greatMatch, // score 60–79
  popularChoice, // score < 60
}

/// Style options for re-generating suggestions
enum RegenerationStyle {
  different,
  moreRelaxed,
  moreLocal,
  morePopular,
}

/// Whether the AI is generating for a single day or the full trip
enum AiGenerationMode { day, trip }

/// Lifecycle of an AI generation request
enum AiGenerationStatus { idle, loading, ready, applying, done, error }

// ---------------------------------------------------------------------------
// AiSuggestion
// ---------------------------------------------------------------------------

class AiSuggestion {
  final String id;
  final String name;
  final String category; // e.g. "Museum", "Restaurant", "Park"
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final String? address;
  final String? placeId;

  /// Estimated time to spend at this place (minutes)
  final int estimatedDuration;

  /// Suggested arrival time string "HH:mm", e.g. "10:00"
  final String? recommendedArrivalTime;

  /// One-line human-readable explanation of why this is recommended
  final String explanation;

  final String source; // always 'ai'
  final double popularityScore; // 0.0–5.0
  final List<String> types; // Google Places-style type strings
  final AiConfidence confidence;

  /// Straight-line distance from previous activity (km)
  final double distanceFromPreviousKm;

  /// True if opening-hours validator flagged this slot as potentially closed
  final bool mayBeClosed;

  /// User's per-item decision (mutable)
  bool isAccepted;
  bool isRejected;

  /// Day index within the trip (for trip-level generation)
  final int? dayIndex;

  AiSuggestion({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.lat,
    this.lng,
    this.address,
    this.placeId,
    required this.estimatedDuration,
    this.recommendedArrivalTime,
    required this.explanation,
    this.source = 'ai',
    required this.popularityScore,
    required this.types,
    required this.confidence,
    this.distanceFromPreviousKm = 0.0,
    this.mayBeClosed = false,
    this.isAccepted = false,
    this.isRejected = false,
    this.dayIndex,
  });

  AiSuggestion copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    double? lat,
    double? lng,
    String? address,
    String? placeId,
    int? estimatedDuration,
    String? recommendedArrivalTime,
    String? explanation,
    String? source,
    double? popularityScore,
    List<String>? types,
    AiConfidence? confidence,
    double? distanceFromPreviousKm,
    bool? mayBeClosed,
    bool? isAccepted,
    bool? isRejected,
    int? dayIndex,
  }) {
    return AiSuggestion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      recommendedArrivalTime:
          recommendedArrivalTime ?? this.recommendedArrivalTime,
      explanation: explanation ?? this.explanation,
      source: source ?? this.source,
      popularityScore: popularityScore ?? this.popularityScore,
      types: types ?? this.types,
      confidence: confidence ?? this.confidence,
      distanceFromPreviousKm:
          distanceFromPreviousKm ?? this.distanceFromPreviousKm,
      mayBeClosed: mayBeClosed ?? this.mayBeClosed,
      isAccepted: isAccepted ?? this.isAccepted,
      isRejected: isRejected ?? this.isRejected,
      dayIndex: dayIndex ?? this.dayIndex,
    );
  }
}

// ---------------------------------------------------------------------------
// AiGenerationOptions
// ---------------------------------------------------------------------------

class AiGenerationOptions {
  final bool includeRestaurants;
  final bool includeCafes;
  final bool focusPopular;
  final bool leaveFreetime;
  final bool familyFriendly;
  final bool localGems;

  const AiGenerationOptions({
    this.includeRestaurants = true,
    this.includeCafes = true,
    this.focusPopular = false,
    this.leaveFreetime = false,
    this.familyFriendly = false,
    this.localGems = false,
  });

  AiGenerationOptions copyWith({
    bool? includeRestaurants,
    bool? includeCafes,
    bool? focusPopular,
    bool? leaveFreetime,
    bool? familyFriendly,
    bool? localGems,
  }) {
    return AiGenerationOptions(
      includeRestaurants: includeRestaurants ?? this.includeRestaurants,
      includeCafes: includeCafes ?? this.includeCafes,
      focusPopular: focusPopular ?? this.focusPopular,
      leaveFreetime: leaveFreetime ?? this.leaveFreetime,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      localGems: localGems ?? this.localGems,
    );
  }
}

// ---------------------------------------------------------------------------
// AiDayBudget
// ---------------------------------------------------------------------------

/// Output of TimeBudgetValidator: realistic breakdown of how a day is spent
class AiDayBudget {
  final int totalActivityMinutes;
  final int totalTravelMinutes;
  final int totalMealBreakMinutes;
  final int totalFreeMinutes;
  final bool isRealistic;
  final String? warningMessage;

  const AiDayBudget({
    required this.totalActivityMinutes,
    required this.totalTravelMinutes,
    required this.totalMealBreakMinutes,
    required this.totalFreeMinutes,
    required this.isRealistic,
    this.warningMessage,
  });

  int get totalMinutes =>
      totalActivityMinutes + totalTravelMinutes + totalMealBreakMinutes;

  String get summaryText {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------------
// AiOptimizationSummary
// ---------------------------------------------------------------------------

/// Shown on AiOptimizationPreviewScreen after user accepts suggestions
class AiOptimizationSummary {
  final int suggestionsAdded;
  final int suggestionsRemovedForTime;
  final int timeSavedMinutes;
  final double totalRouteKm;
  final AiDayBudget budget;

  const AiOptimizationSummary({
    required this.suggestionsAdded,
    required this.suggestionsRemovedForTime,
    required this.timeSavedMinutes,
    required this.totalRouteKm,
    required this.budget,
  });
}
