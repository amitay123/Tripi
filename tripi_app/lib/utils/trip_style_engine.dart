/// Weighted scoring engine that maps trip styles → category score multipliers.
/// Consumed by AiTripService.generateRecommendations() to boost relevant
/// attraction categories based on user's style preferences.
class TripStyleEngine {
  TripStyleEngine._();

  /// Maps style name → category type boosts (0.0 = no boost, 1.0 = 100% extra weight).
  static const Map<String, Map<String, double>> _styleWeights = {
    'Adventure': {
      'Outdoor Activity': 0.30,
      'Hiking Trail': 0.30,
      'Sports': 0.25,
      'Amusement Park': 0.15,
    },
    'Cultural': {
      'Museum': 0.30,
      'Art Gallery': 0.25,
      'Historical Site': 0.30,
      'Theater': 0.20,
    },
    'Food & Culinary': {
      'Restaurant': 0.35,
      'Cafe': 0.25,
      'Food Market': 0.30,
      'Bar': 0.15,
    },
    'Luxury': {
      'Spa': 0.30,
      'Fine Dining': 0.35,
      'Hotel': 0.20,
      'Shopping': 0.20,
    },
    'Nature': {
      'Park': 0.30,
      'Beach': 0.25,
      'Natural Landmark': 0.30,
      'Hiking Trail': 0.25,
    },
    'Relaxation': {
      'Spa': 0.35,
      'Beach': 0.30,
      'Park': 0.20,
      'Cafe': 0.20,
    },
    'Nightlife': {
      'Bar': 0.35,
      'Club': 0.35,
      'Restaurant': 0.15,
      'Theater': 0.15,
    },
    'Family-Friendly': {
      'Amusement Park': 0.35,
      'Zoo': 0.30,
      'Museum': 0.20,
      'Park': 0.25,
    },
    'Budget': {
      'Street Food': 0.30,
      'Park': 0.20,
      'Market': 0.25,
      'Free Attraction': 0.35,
    },
    'Coastal & Beach': {
      'Beach': 0.40,
      'Water Sport': 0.30,
      'Seafood Restaurant': 0.25,
      'Harbor': 0.20,
    },
  };

  /// Returns a merged map of category → additive score boost (0.0–1.0 clamped)
  /// for the given list of selected trip styles.
  static Map<String, double> computeBoosts(List<String> styles) {
    final result = <String, double>{};
    for (final style in styles) {
      final weights = _styleWeights[style] ?? {};
      for (final entry in weights.entries) {
        result[entry.key] = ((result[entry.key] ?? 0.0) + entry.value)
            .clamp(0.0, 1.0);
      }
    }
    return result;
  }

  /// Applies computed boosts to a list of suggestion scores.
  /// Returns modified scores map: placeId → adjusted score.
  static Map<String, double> applyWeights({
    required List<String> styles,
    required Map<String, String> suggestionCategories, // placeId → category
    required Map<String, double> baseScores, // placeId → base score
  }) {
    final boosts = computeBoosts(styles);
    final result = <String, double>{};
    for (final entry in baseScores.entries) {
      final category = suggestionCategories[entry.key] ?? '';
      final boost = boosts[category] ?? 0.0;
      result[entry.key] = (entry.value + boost).clamp(0.0, 1.0);
    }
    return result;
  }
}
