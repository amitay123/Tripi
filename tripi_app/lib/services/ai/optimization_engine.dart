import 'dart:math';
import '../../models/ai_models.dart';

/// Sorts suggestions by the four-priority order defined in the plan:
///   1. Geographic efficiency (nearest-neighbor clustering)
///   2. User preference score (from UserPreferenceService weights)
///   3. Popularity (popularityScore field)
///   4. Pacing balance (alternate high/low intensity)
class OptimizationEngine {
  /// [anchorLat]/[anchorLng]: starting location for geographic sorting.
  /// [categoryWeights]: category → preference weight (0.0–1.0) from UserPreferenceService.
  static List<AiSuggestion> rank({
    required List<AiSuggestion> suggestions,
    required Map<String, double> categoryWeights,
    double? anchorLat,
    double? anchorLng,
  }) {
    if (suggestions.isEmpty) return suggestions;

    // Step 1: geographic nearest-neighbor sort
    final geoSorted = _nearestNeighborSort(suggestions, anchorLat, anchorLng);

    // Step 2: Within nearby clusters, sort by preference then popularity
    // We use a composite score to re-rank within geographic proximity bands
    final ranked = geoSorted.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final prefScore = (categoryWeights[s.category] ?? 0.5) * 40;
      final popScore = (s.popularityScore / 5.0) * 30;
      // Geographic rank already factored in by position; give bonus to early items
      final geoBonus = (geoSorted.length - i) / geoSorted.length * 20;
      // Pacing: alternate intensity — light activities get bonus in odd positions
      final isLightActivity = ['Cafe', 'Park', 'Garden', 'Viewpoint']
          .contains(s.category);
      final pacingBonus = (i.isOdd && isLightActivity) ? 10.0 : 0.0;
      return _ScoredSuggestion(s, prefScore + popScore + geoBonus + pacingBonus);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Step 3: Re-sort for pacing — alternate high/low intensity
    return _balancePacing(ranked.map((e) => e.suggestion).toList());
  }

  // ---------------------------------------------------------------------------
  // Nearest-Neighbor Geographic Sort
  // ---------------------------------------------------------------------------

  static List<AiSuggestion> _nearestNeighborSort(
    List<AiSuggestion> suggestions,
    double? anchorLat,
    double? anchorLng,
  ) {
    if (anchorLat == null || anchorLng == null) return suggestions;
    final remaining = List<AiSuggestion>.from(suggestions);
    final sorted = <AiSuggestion>[];
    double curLat = anchorLat;
    double curLng = anchorLng;

    while (remaining.isNotEmpty) {
      double bestDist = double.infinity;
      int bestIdx = 0;
      for (int i = 0; i < remaining.length; i++) {
        final s = remaining[i];
        if (s.lat == null || s.lng == null) {
          if (bestDist == double.infinity) bestIdx = i;
          continue;
        }
        final d = _haversine(curLat, curLng, s.lat!, s.lng!);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      final chosen = remaining.removeAt(bestIdx);
      // Annotate distance from previous
      final dist = (chosen.lat != null && chosen.lng != null)
          ? _haversine(curLat, curLng, chosen.lat!, chosen.lng!)
          : 0.0;
      sorted.add(chosen.copyWith(distanceFromPreviousKm: dist));
      if (chosen.lat != null) curLat = chosen.lat!;
      if (chosen.lng != null) curLng = chosen.lng!;
    }
    return sorted;
  }

  /// Haversine formula — great-circle distance in km
  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ---------------------------------------------------------------------------
  // Pacing Balance
  // ---------------------------------------------------------------------------

  static List<AiSuggestion> _balancePacing(List<AiSuggestion> suggestions) {
    const lightCategories = {'Cafe', 'Park', 'Garden', 'Viewpoint', 'Beach'};
    const heavyCategories = {'Museum', 'Art Gallery', 'Historical Site'};

    final light =
        suggestions.where((s) => lightCategories.contains(s.category)).toList();
    final heavy =
        suggestions.where((s) => heavyCategories.contains(s.category)).toList();
    final other = suggestions
        .where((s) =>
            !lightCategories.contains(s.category) &&
            !heavyCategories.contains(s.category))
        .toList();

    // Interleave: heavy → other → light → heavy → ...
    final result = <AiSuggestion>[];
    int h = 0, o = 0, l = 0;
    final total = suggestions.length;
    int idx = 0;
    while (result.length < total) {
      if (idx % 3 == 0 && h < heavy.length) {
        result.add(heavy[h++]);
      } else if (idx % 3 == 1 && o < other.length) {
        result.add(other[o++]);
      } else if (l < light.length) {
        result.add(light[l++]);
      } else if (h < heavy.length) {
        result.add(heavy[h++]);
      } else if (o < other.length) {
        result.add(other[o++]);
      } else {
        break;
      }
      idx++;
    }
    return result;
  }
}

class _ScoredSuggestion {
  final AiSuggestion suggestion;
  final double score;
  _ScoredSuggestion(this.suggestion, this.score);
}
