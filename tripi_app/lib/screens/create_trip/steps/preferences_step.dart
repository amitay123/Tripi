import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../models/models.dart';

class PreferencesStep extends StatelessWidget {
  const PreferencesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final draft = tripProvider.draftTrip!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s the vibe?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tailor your trip to your personal style.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildLabel('Trip Goals (Select up to 3)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Relaxation', 'Adventure', 'Culture', 'Food', 'Nature', 'Shopping'
            ].map((goal) {
              final isSelected = draft.preferences.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                onSelected: (selected) {
                  final newPrefs = List<String>.from(draft.preferences);
                  if (selected) {
                    if (newPrefs.length < 3) newPrefs.add(goal);
                  } else {
                    newPrefs.remove(goal);
                  }
                  tripProvider.updateDraft(draft.copyWith(preferences: newPrefs));
                },
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _buildLabel('Planned Pace'),
          Row(
            children: TripPace.values.map((pace) {
              final isSelected = draft.pace == pace;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => tripProvider.updateDraft(draft.copyWith(pace: pace)),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getPaceIcon(pace),
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pace.name[0].toUpperCase() + pace.name.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151)),
      ),
    );
  }

  IconData _getPaceIcon(TripPace pace) {
    switch (pace) {
      case TripPace.relaxed: return Icons.airline_seat_recline_extra;
      case TripPace.balanced: return Icons.directions_walk;
      case TripPace.intensive: return Icons.directions_run;
    }
  }
}
