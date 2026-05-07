import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_models.dart';

/// Persists the user's AI interaction history to Supabase.
///
/// Tracks:
///   - accepted/rejected categories
///   - visited placeIds (cross-trip memory)
///   - repeatedly-rejected place types
///   - learned pace + intensity preferences
///
/// This is the foundation for cross-trip memory and preference-weighted
/// suggestion ranking. It is loaded on demand and cached in memory for
/// the session lifetime.
class UserPreferenceService extends ChangeNotifier {
  static const _table = 'user_ai_preferences';

  Map<String, int> acceptedCategories = {};
  Map<String, int> rejectedCategories = {};
  Set<String> visitedPlaceIds = {};
  Map<String, int> rejectedPlaceTypes = {};
  String preferredPace = 'balanced';
  double preferredIntensity = 0.5; // 0.0 relaxed → 1.0 intensive

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // -------------------------------------------------------------------------
  // Load / Save
  // -------------------------------------------------------------------------

  Future<void> load(String userId) async {
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row != null) {
        acceptedCategories = _jsonToIntMap(row['accepted_categories']);
        rejectedCategories = _jsonToIntMap(row['rejected_categories']);
        visitedPlaceIds = _jsonToStringSet(row['visited_place_ids']);
        rejectedPlaceTypes = _jsonToIntMap(row['rejected_place_types']);
        preferredPace = row['preferred_pace'] ?? 'balanced';
        preferredIntensity = (row['preferred_intensity'] as num?)?.toDouble() ?? 0.5;
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[UserPreferenceService] load error: $e');
      _loaded = true; // Still allow operation with defaults
    }
  }

  Future<void> save(String userId) async {
    try {
      await Supabase.instance.client.from(_table).upsert({
        'user_id': userId,
        'accepted_categories': jsonEncode(acceptedCategories),
        'rejected_categories': jsonEncode(rejectedCategories),
        'visited_place_ids': jsonEncode(visitedPlaceIds.toList()),
        'rejected_place_types': jsonEncode(rejectedPlaceTypes),
        'preferred_pace': preferredPace,
        'preferred_intensity': preferredIntensity,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[UserPreferenceService] save error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Record accepted / rejected
  // -------------------------------------------------------------------------

  void recordAccepted(List<AiSuggestion> suggestions) {
    for (final s in suggestions) {
      acceptedCategories[s.category] =
          (acceptedCategories[s.category] ?? 0) + 1;
      if (s.placeId != null) visitedPlaceIds.add(s.placeId!);
      // Reward this type
      for (final type in s.types) {
        if (rejectedPlaceTypes.containsKey(type)) {
          rejectedPlaceTypes[type] =
              (rejectedPlaceTypes[type]! - 1).clamp(0, 999);
        }
      }
    }
    _updateIntensity(suggestions, accepted: true);
    notifyListeners();
  }

  void recordRejected(List<AiSuggestion> suggestions) {
    for (final s in suggestions) {
      rejectedCategories[s.category] =
          (rejectedCategories[s.category] ?? 0) + 1;
      for (final type in s.types) {
        rejectedPlaceTypes[type] = (rejectedPlaceTypes[type] ?? 0) + 1;
      }
    }
    _updateIntensity(suggestions, accepted: false);
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  /// Returns a 0.0–1.0 preference weight for a given category.
  Map<String, double> getWeightedCategoryScores() {
    final allCategories = {
      ...acceptedCategories.keys,
      ...rejectedCategories.keys,
    };
    final result = <String, double>{};
    for (final cat in allCategories) {
      final accepted = acceptedCategories[cat] ?? 0;
      final rejected = rejectedCategories[cat] ?? 0;
      final total = accepted + rejected;
      if (total == 0) {
        result[cat] = 0.5;
      } else {
        result[cat] = accepted / total;
      }
    }
    return result;
  }

  /// Returns true if this type has been rejected ≥ 3 times without a recent accept.
  bool shouldAvoidType(String type) {
    return (rejectedPlaceTypes[type] ?? 0) >= 3;
  }

  double getCategoryPreferenceScore(String category) {
    final scores = getWeightedCategoryScores();
    return scores[category] ?? 0.5;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  void _updateIntensity(List<AiSuggestion> suggestions, {required bool accepted}) {
    // High-intensity activities (museums, landmarks) increase intensity score
    const intensiveTypes = {'Museum', 'Art Gallery', 'Historical Site', 'Activity'};
    final intensiveCount =
        suggestions.where((s) => intensiveTypes.contains(s.category)).length;
    final ratio = suggestions.isEmpty ? 0.0 : intensiveCount / suggestions.length;
    if (accepted) {
      // Slide toward ratio with momentum
      preferredIntensity = (preferredIntensity * 0.8 + ratio * 0.2).clamp(0.0, 1.0);
    }
  }

  static Map<String, int> _jsonToIntMap(dynamic json) {
    if (json == null) return {};
    final Map<String, dynamic> raw =
        json is String ? jsonDecode(json) : Map<String, dynamic>.from(json);
    return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Set<String> _jsonToStringSet(dynamic json) {
    if (json == null) return {};
    final List<dynamic> raw = json is String ? jsonDecode(json) : List.from(json);
    return raw.cast<String>().toSet();
  }
}
