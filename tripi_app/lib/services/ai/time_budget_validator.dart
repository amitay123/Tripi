import 'dart:math';
import '../../models/ai_models.dart';

/// Validates that the total time budget for a day is realistic.
///
/// Day constraints:
///   - Day starts at [dayStartHour] (default 09:00)
///   - Day hard-ends at 22:00
///   - Reserves 45 min for lunch if no restaurant between 12–14:00
///   - Reserves 30 min for dinner if no restaurant between 18–20:00
///   - 10 min buffer per activity transition
class TimeBudgetValidator {
  static const int _dayStartHour = 9;
  static const int _dayEndHour = 22;
  static const int _totalDayMinutes =
      (_dayEndHour - _dayStartHour) * 60; // 780 min
  static const int _transitionBuffer = 10;
  static const int _lunchReserve = 45;
  static const int _dinnerReserve = 30;

  /// Returns the trimmed list + the AiDayBudget for that day.
  static ({List<AiSuggestion> suggestions, AiDayBudget budget}) validate(
    List<AiSuggestion> suggestions, {
    String? dayStartTime, // "HH:mm" overrides _dayStartHour
  }) {
    if (suggestions.isEmpty) {
      return (
        suggestions: suggestions,
        budget: const AiDayBudget(
          totalActivityMinutes: 0,
          totalTravelMinutes: 0,
          totalMealBreakMinutes: 0,
          totalFreeMinutes: _totalDayMinutes,
          isRealistic: true,
        )
      );
    }

    // Calculate total activity + travel time
    int activityMinutes =
        suggestions.fold(0, (sum, s) => sum + s.estimatedDuration);
    int travelMinutes = suggestions.fold(0, (sum, s) {
      // Rough travel: assume avg 15 min between activities
      return sum + (s.distanceFromPreviousKm > 0
          ? min(60, (s.distanceFromPreviousKm / 30.0 * 60).round())
          : 10);
    });
    int transitionMinutes = suggestions.length * _transitionBuffer;

    // Check if meals are covered
    final hasLunchCovered = suggestions.any((s) =>
        s.category == 'Restaurant' &&
        s.recommendedArrivalTime != null &&
        _hourBetween(s.recommendedArrivalTime!, 12, 14));
    final hasDinnerCovered = suggestions.any((s) =>
        s.category == 'Restaurant' &&
        s.recommendedArrivalTime != null &&
        _hourBetween(s.recommendedArrivalTime!, 18, 21));

    int mealMinutes = 0;
    if (!hasLunchCovered) mealMinutes += _lunchReserve;
    if (!hasDinnerCovered) mealMinutes += _dinnerReserve;

    final initialTotalUsed =
        activityMinutes + travelMinutes + transitionMinutes + mealMinutes;
    final isRealistic = initialTotalUsed <= _totalDayMinutes;

    String? warning;
    if (!isRealistic) {
      final over = initialTotalUsed - _totalDayMinutes;
      warning =
          'Day is ${_formatMinutes(over)} over budget. Some activities may be removed.';
    }

    // Trim suggestions if over budget
    var trimmed = List<AiSuggestion>.from(suggestions);
    int currentTotalUsed = initialTotalUsed;

    while (trimmed.isNotEmpty && currentTotalUsed > _totalDayMinutes) {
      final removed = trimmed.removeLast();
      final removedTravel = (removed.distanceFromPreviousKm > 0
          ? min(60, (removed.distanceFromPreviousKm / 30.0 * 60).round())
          : 10);
      currentTotalUsed -= (removed.estimatedDuration + _transitionBuffer + removedTravel);
    }

    // Recalculate final metrics
    final finalActivity = trimmed.fold(0, (sum, s) => sum + s.estimatedDuration);
    final finalTravel = trimmed.fold(0, (sum, s) {
      return sum + (s.distanceFromPreviousKm > 0
          ? min(60, (s.distanceFromPreviousKm / 30.0 * 60).round())
          : 10);
    });
    final finalTransition = trimmed.length * _transitionBuffer;

    return (
      suggestions: trimmed,
      budget: AiDayBudget(
        totalActivityMinutes: finalActivity,
        totalTravelMinutes: finalTravel,
        totalMealBreakMinutes: mealMinutes,
        totalFreeMinutes: max(
            0,
            _totalDayMinutes -
                finalActivity -
                finalTravel -
                finalTransition -
                mealMinutes),
        isRealistic: isRealistic,
        warningMessage: warning,
      )
    );
  }


  static bool _hourBetween(String hhmm, int startH, int endH) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]) ?? -1;
    return h >= startH && h < endH;
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}
