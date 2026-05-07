import '../models/models.dart';
import 'user_preference_service.dart';

/// Cross-trip memory: tracks all placeIds the user has visited or accepted.
///
/// Seeded at generation time from:
///   1. Every activity across ALL user trips (in-memory from TripProvider)
///   2. UserPreferenceService.visitedPlaceIds (persisted cross-session)
///
/// This guarantees the AI never re-suggests places the user has already been,
/// even on future trips.
class VisitedPlacesRegistry {
  final Set<String> _visitedPlaceIds = {};
  final Set<String> _visitedActivityTitles = {}; // fallback for missing placeIds

  /// Populate from all trips in local state.
  void seedFromTrips(List<Trip> trips) {
    for (final trip in trips) {
      for (final day in trip.days) {
        for (final activity in day.activities) {
          if (activity.placeId != null && activity.placeId!.isNotEmpty) {
            _visitedPlaceIds.add(activity.placeId!);
          }
          // Also track by title as a fuzzy fallback
          _visitedActivityTitles.add(activity.title.toLowerCase().trim());
        }
      }
    }
  }

  /// Populate from the persisted preference service.
  void seedFromPreferences(UserPreferenceService prefs) {
    _visitedPlaceIds.addAll(prefs.visitedPlaceIds);
  }

  /// Returns true if this placeId has been visited.
  bool isVisited(String? placeId) {
    if (placeId == null || placeId.isEmpty) return false;
    return _visitedPlaceIds.contains(placeId);
  }

  /// Fuzzy check by activity title (for places without a placeId).
  bool isVisitedByTitle(String name) {
    return _visitedActivityTitles.contains(name.toLowerCase().trim());
  }

  /// Filter a list of place maps, removing visited ones.
  /// Each map is expected to have 'placeId' and 'name' keys.
  List<Map<String, dynamic>> filterVisited(List<Map<String, dynamic>> places) {
    return places.where((p) {
      final placeId = p['placeId'] as String?;
      final name = p['name'] as String? ?? '';
      return !isVisited(placeId) && !isVisitedByTitle(name);
    }).toList();
  }

  Set<String> get allVisitedIds => Set.unmodifiable(_visitedPlaceIds);

  void clear() {
    _visitedPlaceIds.clear();
    _visitedActivityTitles.clear();
  }
}
