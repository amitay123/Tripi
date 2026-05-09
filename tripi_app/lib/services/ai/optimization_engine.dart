import 'dart:math';
import '../../models/ai_models.dart';

/// Ranks suggestions within each recommendation section independently.
///
/// Priority order per section:
///   1. Relevance to active toggles
///   2. Tourist popularity / review count
///   3. Rating
///   4. Geographic efficiency (nearest-neighbour within section)
class OptimizationEngine {
  // ── Section-aware ranking ─────────────────────────────────────────────────

  /// Ranks each section of [set] independently and returns a new
  /// [AiRecommendationSet] with sections sorted highest-score first.
  static AiRecommendationSet rankSections({
    required AiRecommendationSet set,
    required AiGenerationOptions options,
    double? anchorLat,
    double? anchorLng,
  }) {
    final landmarks = _rankSection(
      set.landmarks,
      section: RecommendationSection.landmark,
      options: options,
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      maxResults: options.leaveFreetime ? 5 : 10,
    );

    final localGems = _rankSection(
      set.localGems,
      section: RecommendationSection.localGem,
      options: options,
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      maxResults: options.leaveFreetime ? 3 : 8,
    );

    final food = _rankFoodSection(
      set.food,
      options: options,
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      maxResults: options.leaveFreetime ? 4 : 8,
    );

    return AiRecommendationSet(
      landmarks: landmarks,
      localGems: localGems,
      food: food,
    );
  }

  static List<AiSuggestion> _rankSection(
    List<AiSuggestion> suggestions, {
    required RecommendationSection section,
    required AiGenerationOptions options,
    double? anchorLat,
    double? anchorLng,
    int maxResults = 10,
  }) {
    if (suggestions.isEmpty) return [];

    final geoSorted = _nearestNeighborSort(suggestions, anchorLat, anchorLng);

    final scored = geoSorted.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;

      double score = 0;

      // Rating weight (0–5 → 0–40)
      score += s.popularityScore * 8.0;

      // Review count (log-scaled, 0–30)
      score += _logScale(s.userRatingsTotal, max: 30);

      // Geographic proximity bonus (0–15)
      score += (geoSorted.length - i) / geoSorted.length * 15;

      // Section-specific toggle modifiers
      if (section == RecommendationSection.landmark) {
        if (options.focusPopular) {
          // Strongly boost iconic places
          if (s.userRatingsTotal >= 5000) {
            score += 20;
          } else if (s.userRatingsTotal >= 1000) {
            score += 10;
          }
          if (s.popularityScore >= 4.7) {
            score += 8;
          }
        }
        if (options.familyFriendly) {
          const familyCats = {'Museum', 'Park', 'Zoo', 'Aquarium', 'Amusement Park'};
          if (familyCats.contains(s.category)) score += 10;
        }
        // Penalise bars/nightlife in landmark section if family mode
        if (options.familyFriendly && s.category == 'Bar') score -= 30;
      }

      if (section == RecommendationSection.localGem) {
        // Local gems: quality > quantity
        score += s.popularityScore * 5; // extra weight on rating
        if (s.isLocalGem) score += 15;
        // Penalise too-famous places (not really a gem)
        if (s.userRatingsTotal > 500) score -= 15;
        if (options.localGems) score += 10; // bonus when toggle is active
      }

      return _ScoredSuggestion(
        s.copyWith(recommendationScore: score.clamp(0, 100)),
        score,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(maxResults).map((e) {
      final s = e.suggestion;
      final confidence = _scoreToConfidence(e.score);
      return s.copyWith(confidence: confidence);
    }).toList();
  }

  static List<AiSuggestion> _rankFoodSection(
    List<AiSuggestion> suggestions, {
    required AiGenerationOptions options,
    double? anchorLat,
    double? anchorLng,
    int maxResults = 8,
  }) {
    if (suggestions.isEmpty) return [];

    // Separate restaurants and cafes
    final restaurants =
        suggestions.where((s) => s.category == 'Restaurant').toList();
    final cafes = suggestions
        .where((s) => s.category == 'Cafe')
        .toList();

    List<AiSuggestion> pool;
    if (options.includeRestaurants && options.includeCafes) {
      // Balanced mix: alternate restaurant/cafe
      pool = _interleave(
        _sortByScore(restaurants),
        _sortByScore(cafes),
      );
    } else if (options.includeRestaurants) {
      pool = _sortByScore(restaurants);
    } else {
      pool = _sortByScore(cafes);
    }

    final geoSorted = _nearestNeighborSort(pool, anchorLat, anchorLng);

    return geoSorted.take(maxResults).toList().asMap().entries.map((e) {
      final s = e.value;
      final score = s.popularityScore * 8 + _logScale(s.userRatingsTotal, max: 30);
      final confidence = _scoreToConfidence(score);
      return s.copyWith(
        confidence: confidence,
        recommendationScore: score.clamp(0, 100),
      );
    }).toList();
  }

  // ── Legacy flat rank (kept for backward compat) ───────────────────────────

  static List<AiSuggestion> rank({
    required List<AiSuggestion> suggestions,
    required Map<String, double> categoryWeights,
    double? anchorLat,
    double? anchorLng,
    AiGenerationOptions? options,
  }) {
    if (suggestions.isEmpty) return suggestions;

    final geoSorted = _nearestNeighborSort(suggestions, anchorLat, anchorLng);

    final ranked = geoSorted.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;

      final prefScore = (categoryWeights[s.category] ?? 0.5) * 40;
      final popScore = (s.popularityScore / 5.0) * 30;
      final geoBonus = (geoSorted.length - i) / geoSorted.length * 20;

      final isLight =
          ['Cafe', 'Park', 'Garden', 'Viewpoint'].contains(s.category);
      final pacingBonus = (i.isOdd && isLight) ? 10.0 : 0.0;

      double toggleBonus = 0.0;
      if (options != null) {
        if (options.localGems) {
          if (s.isLocalGem) toggleBonus += 15.0;
          if (s.popularityScore >= 4.8) toggleBonus -= 8.0;
        }
        if (options.focusPopular) {
          if (s.popularityScore >= 4.7) toggleBonus += 12.0;
        }
        if (options.familyFriendly) {
          const familyCategories = {
            'Park',
            'Museum',
            'Historical Site',
            'Market'
          };
          if (familyCategories.contains(s.category)) toggleBonus += 8.0;
        }
        if (options.includeRestaurants && s.category == 'Restaurant') {
          toggleBonus += 5.0;
        }
        if (options.includeCafes && s.category == 'Cafe') {
          toggleBonus += 5.0;
        }
      }

      final totalScore =
          prefScore + popScore + geoBonus + pacingBonus + toggleBonus;
      return _ScoredSuggestion(s, totalScore);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return _balancePacing(ranked.map((e) => e.suggestion).toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<AiSuggestion> _sortByScore(List<AiSuggestion> list) {
    final copy = List<AiSuggestion>.from(list);
    copy.sort((a, b) {
      final sa = a.popularityScore * 8 + _logScale(a.userRatingsTotal, max: 30);
      final sb = b.popularityScore * 8 + _logScale(b.userRatingsTotal, max: 30);
      return sb.compareTo(sa);
    });
    return copy;
  }

  static List<AiSuggestion> _interleave(
      List<AiSuggestion> a, List<AiSuggestion> b) {
    final result = <AiSuggestion>[];
    final len = max(a.length, b.length);
    for (int i = 0; i < len; i++) {
      if (i < a.length) result.add(a[i]);
      if (i < b.length) result.add(b[i]);
    }
    return result;
  }

  /// Log-scaled popularity: ln(reviews+1) / ln(maxReviews+1) * maxScore
  static double _logScale(int reviews, {required double max}) {
    const maxReviews = 50000;
    if (reviews <= 0) return 0;
    return (log(reviews + 1) / log(maxReviews + 1)) * max;
  }

  static AiConfidence _scoreToConfidence(double score) {
    if (score >= 70) {
      return AiConfidence.highlyRecommended;
    }
    if (score >= 45) {
      return AiConfidence.greatMatch;
    }
    return AiConfidence.popularChoice;
  }

  // ── Nearest-Neighbor Geographic Sort ─────────────────────────────────────

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
      final dist = (chosen.lat != null && chosen.lng != null)
          ? _haversine(curLat, curLng, chosen.lat!, chosen.lng!)
          : 0.0;
      sorted.add(chosen.copyWith(distanceFromPreviousKm: dist));
      if (chosen.lat != null) curLat = chosen.lat!;
      if (chosen.lng != null) curLng = chosen.lng!;
    }
    return sorted;
  }

  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ── Pacing Balance (legacy) ───────────────────────────────────────────────

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
