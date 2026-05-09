import 'dart:math';
import '../../models/models.dart';

/// Handles the logic of re-ordering activities within a trip day
/// to minimize travel time and optimize the schedule.
class AiSchedulingService {
  /// Optimizes the sequence of activities for a given day.
  /// 
  /// Currently uses a greedy "Nearest Neighbor" approach starting from 
  /// the specified [startTime].
  static List<Activity> optimizeRoute({
    required List<Activity> activities,
    required String dayStartTime,
    double? startLat,
    double? startLng,
  }) {
    if (activities.isEmpty) return [];
    if (activities.length == 1) {
      // Single activity just needs a start time
      return [
        activities[0].copyWith(
          startTime: dayStartTime,
          endTime: _calculateEndTime(dayStartTime, activities[0].duration),
        )
      ];
    }

    final List<Activity> remaining = List<Activity>.from(activities);
    final List<Activity> optimized = [];
    
    double curLat = startLat ?? (activities.first.lat ?? 0.0);
    double curLng = startLng ?? (activities.first.lng ?? 0.0);
    String curTime = dayStartTime;

    while (remaining.isNotEmpty) {
      // Find closest activity to current location
      int bestIdx = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final a = remaining[i];
        if (a.lat == null || a.lng == null) {
          if (minDistance == double.infinity) bestIdx = i;
          continue;
        }

        final dist = _haversine(curLat, curLng, a.lat!, a.lng!);
        if (dist < minDistance) {
          minDistance = dist;
          bestIdx = i;
        }
      }

      final chosen = remaining.removeAt(bestIdx);
      
      // Calculate transport time (fallback estimation)
      final transportDuration = minDistance == double.infinity 
          ? 15 
          : _estimateTransportMinutes(minDistance);
      
      // Update time for this activity
      final arrivalTime = _addMinutes(curTime, transportDuration);
      final departureTime = _addMinutes(arrivalTime, chosen.duration);

      optimized.add(chosen.copyWith(
        startTime: arrivalTime,
        endTime: departureTime,
        transportModeFromPrevious: TravelMode.driving, // Default
        travelDurationFromPrevious: transportDuration,
      ));

      // Update current state
      if (chosen.lat != null && chosen.lng != null) {
        curLat = chosen.lat!;
        curLng = chosen.lng!;
      }
      curTime = departureTime;
    }

    return optimized;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _calculateEndTime(String startTime, int durationMinutes) {
    return _addMinutes(startTime, durationMinutes);
  }

  static String _addMinutes(String timeStr, int minutesToAdd) {
    try {
      final parts = timeStr.split(':');
      int hours = int.parse(parts[0]);
      int mins = int.parse(parts[1]);

      mins += minutesToAdd;
      hours += mins ~/ 60;
      mins = mins % 60;
      hours = hours % 24;

      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  static int _estimateTransportMinutes(double distanceKm) {
    // Assume average city speed of 30km/h + 5 mins buffer
    // time = (dist / 30) * 60 + 5
    return ((distanceKm / 30.0) * 60).ceil() + 5;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
