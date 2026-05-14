import 'dart:math';
import '../../models/ai_models.dart';

/// Fills free time gaps in a generated itinerary with lightweight suggestions.
///
/// A "gap" is defined as free time ≥ 45 minutes between two consecutive
/// activities. The filler inserts one short suggestion (cafe, viewpoint,
/// park stroll) per gap.
class GapFiller {
  static const int _minGapMinutes = 45;

  /// Returns the extended list with gap-fillers inserted inline.
  static List<AiSuggestion> fill({
    required List<AiSuggestion> suggestions,
    required String dayStartTime, // "HH:mm"
    required double? anchorLat,
    required double? anchorLng,
  }) {
    if (suggestions.isEmpty) return suggestions;

    int currentMinutes = _parseTime(dayStartTime) ?? 9 * 60;
    final result = <AiSuggestion>[];
    int gapIndex = 0;

    for (final s in suggestions) {
      final arrivalMinutes = s.recommendedArrivalTime != null
          ? (_parseTime(s.recommendedArrivalTime!) ?? currentMinutes)
          : currentMinutes;

      final gap = arrivalMinutes - currentMinutes;
      if (gap >= _minGapMinutes) {
        // Insert a quick filler suggestion
        result.add(_buildFiller(
          gapIndex: gapIndex++,
          startMinutes: currentMinutes,
          gapMinutes: gap,
          anchorLat: anchorLat,
          anchorLng: anchorLng,
        ));
      }

      result.add(s);
      currentMinutes = arrivalMinutes + s.estimatedDuration;
    }

    return result;
  }

  static AiSuggestion _buildFiller({
    required int gapIndex,
    required int startMinutes,
    required int gapMinutes,
    required double? anchorLat,
    required double? anchorLng,
  }) {
    const templates = [
      _FillerTemplate(
        name: 'Nearby Café Break',
        category: 'Cafe',
        explanation: 'Free gap spotted · Perfect time for coffee & people-watching',
        duration: 30,
        types: ['cafe'],
        popularity: 4.2,
      ),
      _FillerTemplate(
        name: 'Scenic Viewpoint',
        category: 'Viewpoint',
        explanation: 'Free gap spotted · Great views of the city from here',
        duration: 20,
        types: ['viewpoint'],
        popularity: 4.4,
      ),
      _FillerTemplate(
        name: 'Local Park Stroll',
        category: 'Park',
        explanation: 'Free gap spotted · A relaxing walk among locals',
        duration: 30,
        types: ['park'],
        popularity: 4.0,
      ),
    ];

    final t = templates[gapIndex % templates.length];
    return AiSuggestion(
      id: 'gap_filler_$gapIndex',
      name: t.name,
      category: t.category,
      lat: anchorLat != null ? anchorLat + (Random().nextDouble() * 0.004 - 0.002) : null,
      lng: anchorLng != null ? anchorLng + (Random().nextDouble() * 0.004 - 0.002) : null,
      estimatedDuration: t.duration,
      recommendedArrivalTime: _formatTime(startMinutes),
      explanation: t.explanation,
      popularityScore: t.popularity,
      types: t.types,
      confidence: AiConfidence.greatMatch,
      distanceFromPreviousKm: 0.3,
      source: 'ai',
    );
  }

  static int? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _formatTime(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _FillerTemplate {
  final String name;
  final String category;
  final String explanation;
  final int duration;
  final List<String> types;
  final double popularity;

  const _FillerTemplate({
    required this.name,
    required this.category,
    required this.explanation,
    required this.duration,
    required this.types,
    required this.popularity,
  });
}
