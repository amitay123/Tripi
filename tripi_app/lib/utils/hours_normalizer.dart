class HoursNormalizerUtil {
  static String normalizeHoursString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Hours unavailable';
    String text = raw;
    final colonIdx = raw.indexOf(': ');
    if (colonIdx != -1) text = raw.substring(colonIdx + 2).trim();
    if (text.isEmpty) return 'Hours unavailable';
    if (text.toLowerCase() == 'closed') return 'Closed';
    if (text.toLowerCase().contains('open 24 hours')) return 'Open 24 hours';
    if (!text.contains('AM') && !text.contains('PM')) {
      text = _convert24To12(text);
    }
    return text;
  }

  static String? getTodayHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return null;
    final weekdayText = openingHours['weekday_text'];
    if (weekdayText == null || weekdayText is! List || weekdayText.isEmpty) {
      return null;
    }
    final days = List<String>.from(weekdayText);
    // weekday: Mon=1..Sun=7; weekday_text index: 0=Mon..6=Sun
    final int dayIndex = DateTime.now().weekday - 1;
    if (dayIndex < 0 || dayIndex >= days.length) return null;
    return normalizeHoursString(days[dayIndex]);
  }

  static bool? isOpenNow(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return null;
    return openingHours['open_now'] as bool?;
  }

  static List<String> getAllHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return [];
    final weekdayText = openingHours['weekday_text'];
    if (weekdayText == null || weekdayText is! List) return [];
    return (weekdayText as List)
        .map((e) => normalizeHoursString(e?.toString()))
        .toList();
  }

  static String _convert24To12(String text) {
    final regex = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    return text.replaceAllMapped(regex, (match) {
      int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      if (hour < 0 || hour > 23) return match.group(0)!;
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }
      final minuteStr =
          minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
      return '$hour$minuteStr $period';
    });
  }
}
