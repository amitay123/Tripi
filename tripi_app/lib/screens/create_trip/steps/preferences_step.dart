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
            'Trip Preferences',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Customize your journey based on your style and goals.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildLabel('TRIP TYPE'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TripType.values.map((type) {
              final isSelected = draft.tripType == type;
              return ChoiceChip(
                label: Text(_formatEnum(type.name)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) tripProvider.updateDraft(draft.copyWith(tripType: type));
                },
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _buildLabel('TRIP GOALS'),
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
                    newPrefs.add(goal);
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _buildLabel('PLANNED PACE'),
          Row(
            children: TripPace.values.map((pace) {
              final isSelected = draft.pace == pace;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => tripProvider.updateDraft(draft.copyWith(pace: pace)),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(height: 4),
                          Text(
                            _getPaceEstimate(pace),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? const Color(0xFF2563EB).withOpacity(0.8) : const Color(0xFF9CA3AF),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563), fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }

  String _getPaceEstimate(TripPace pace) {
    switch (pace) {
      case TripPace.relaxed: return '3-4 hours/day';
      case TripPace.balanced: return '6-7 hours/day';
      case TripPace.intensive: return '9-10 hours/day';
      default: return '6-7 hours/day';
    }
  }

  IconData _getPaceIcon(TripPace pace) {
    switch (pace) {
      case TripPace.relaxed: return Icons.airline_seat_recline_extra;
      case TripPace.balanced: return Icons.directions_walk;
      case TripPace.intensive: return Icons.directions_run;
      default: return Icons.directions_walk;
    }
  }

  String _formatEnum(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }
}

