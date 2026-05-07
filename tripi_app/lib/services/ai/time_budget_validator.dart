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

    final totalUsed =
        activityMinutes + travelMinutes + transitionMinutes + mealMinutes;
    final freeMinutes = max(0, _totalDayMinutes - totalUsed);
    final isRealistic = totalUsed <= _totalDayMinutes;

    String? warning;
    if (!isRealistic) {
      final over = totalUsed - _totalDayMinutes;
      warning =
          'Day is ${_formatMinutes(over)} over budget. Some activities may be removed.';
    }

    // Trim suggestions if over budget
    final trimmed = _trim(suggestions, activityMinutes, travelMinutes,
        transitionMinutes, mealMinutes);

    // Recalculate after trim
    final trimmedActivity =
        trimmed.fold(0, (sum, s) => sum + s.estimatedDuration);

    return (
      suggestions: trimmed,
      budget: AiDayBudget(
        totalActivityMinutes: trimmedActivity,
        totalTravelMinutes: travelMinutes,
        totalMealBreakMinutes: mealMinutes,
        totalFreeMinutes: max(
            0,
            _totalDayMinutes -
                trimmedActivity -
                travelMinutes -
                transitionMinutes -
                mealMinutes),
        isRealistic: isRealistic,
        warningMessage: warning,
      )
    );
  }

  static List<AiSuggestion> _trim(
    List<AiSuggestion> suggestions,
    int activityMins,
    int travelMins,
    int transitionMins,
    int mealMins,
  ) {
    int total = activityMins + travelMins + transitionMins + mealMins;
    if (total <= _totalDayMinutes) return suggestions;

    // Remove suggestions from the end (least important) until it fits
    final result = List<AiSuggestion>.from(suggestions);
    while (result.isNotEmpty && total > _totalDayMinutes) {
      final removed = result.removeLast();
      total -= removed.estimatedDuration + _transitionBuffer;
    }
    return result;
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
