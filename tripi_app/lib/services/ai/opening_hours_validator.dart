import 'dart:math';
import '../../models/ai_models.dart';

/// Validates whether an AI-suggested activity is likely open at the proposed
/// arrival time, based on category-level heuristics.
///
/// Since the mock AI doesn't call a real Places API, we use the category
/// and proposed time slot to flag potential issues. A real implementation
/// can swap this with a live Google Places opening hours lookup.
class OpeningHoursValidator {
  // Category → list of open windows [openHour, closeHour] (24h)
  static const Map<String, List<List<int>>> _categoryHours = {
    'Museum': [
      [9, 18]
    ],
    'Art Gallery': [
      [10, 18]
    ],
    'Historical Site': [
      [9, 19]
    ],
    'Landmark': [
      [0, 24]
    ], // Usually always open
    'Park': [
      [6, 21]
    ],
    'Restaurant': [
      [12, 15],
      [18, 23]
    ], // lunch + dinner
    'Cafe': [
      [7, 21]
    ],
    'Bar': [
      [17, 3]
    ], // late night
    'Shopping': [
      [10, 21]
    ],
    'Market': [
      [8, 14]
    ],
    'Beach': [
      [7, 20]
    ],
    'Temple': [
      [6, 18]
    ],
    'Church': [
      [8, 19]
    ],
    'Garden': [
      [8, 20]
    ],
    'Zoo': [
      [9, 18]
    ],
    'Aquarium': [
      [9, 19]
    ],
    'Theater': [
      [19, 23]
    ],
    'Viewpoint': [
      [6, 22]
    ],
    'Activity': [
      [9, 18]
    ],
  };

  /// Returns a copy of each suggestion flagged with [mayBeClosed] if the
  /// recommended arrival time falls outside the typical window.
  static List<AiSuggestion> validate(List<AiSuggestion> suggestions) {
    return suggestions.map((s) {
      final time = s.recommendedArrivalTime;
      if (time == null) return s;
      final hour = _parseHour(time);
      if (hour == null) return s;
      final windows = _categoryHours[s.category];
      if (windows == null) return s; // Unknown category — assume open
      final isOpen = windows.any((w) => _isInWindow(hour, w[0], w[1]));
      return s.copyWith(mayBeClosed: !isOpen);
    }).toList();
  }

  static int? _parseHour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    return int.tryParse(parts[0]);
  }

  static bool _isInWindow(int hour, int open, int close) {
    if (close > open) {
      return hour >= open && hour < close;
    } else {
      // Overnight window, e.g. 22:00–03:00
      return hour >= open || hour < close;
    }
  }

  /// Suggests a better time within the open window for a flagged suggestion.
  static String? suggestBetterTime(AiSuggestion suggestion) {
    final windows = _categoryHours[suggestion.category];
    if (windows == null || windows.isEmpty) return null;
    // Return the start of the first window
    return '${windows.first[0].toString().padLeft(2, '0')}:00';
  }
}

/// Assigns a [AiConfidence] label to each suggestion based on a composite
/// score computed from:
///   - User preference match     (0–40 pts)
///   - Popularity score          (0–30 pts)
///   - Geographic proximity      (0–20 pts)
///   - Category diversity        (0–10 pts)
class ConfidenceLabelAssigner {
  static AiConfidence assign({
    required AiSuggestion suggestion,
    required Map<String, double> categoryWeights,
    required bool isNearby, // true if distanceFromPreviousKm < 2.0
    required bool isCategoryDiverse,
  }) {
    double score = 0;

    // Preference match (0–40)
    final weight = categoryWeights[suggestion.category] ?? 0.5;
    score += weight * 40;

    // Popularity (0–30): maps 0–5 scale to 0–30
    score += min(30, (suggestion.popularityScore / 5.0) * 30);

    // Geographic proximity (0–20)
    if (isNearby) score += 20;

    // Diversity (0–10)
    if (isCategoryDiverse) score += 10;

    if (score >= 80) return AiConfidence.highlyRecommended;
    if (score >= 60) return AiConfidence.greatMatch;
    return AiConfidence.popularChoice;
  }

  /// Batch-assign confidence to an entire list of suggestions.
  static List<AiSuggestion> assignAll({
    required List<AiSuggestion> suggestions,
    required Map<String, double> categoryWeights,
  }) {
    final seenCategories = <String>{};
    return suggestions.asMap().entries.map((entry) {
      final s = entry.value;
      final isNearby = s.distanceFromPreviousKm < 2.0;
      final isCategoryDiverse = !seenCategories.contains(s.category);
      seenCategories.add(s.category);
      final confidence = assign(
        suggestion: s,
        categoryWeights: categoryWeights,
        isNearby: isNearby,
        isCategoryDiverse: isCategoryDiverse,
      );
      return s.copyWith(confidence: confidence);
    }).toList();
  }
}
