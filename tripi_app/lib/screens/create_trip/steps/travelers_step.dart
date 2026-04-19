import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../models/models.dart';

class TravelersStep extends StatelessWidget {
  const TravelersStep({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final draft = tripProvider.draftTrip!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who\'s coming along?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your travel party.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          _buildCounterRow(
            'Total Travelers',
            draft.travelersCount,
            (val) => tripProvider.updateDraft(draft.copyWith(travelersCount: val)),
          ),
          const SizedBox(height: 40),
          const Text(
            'Travel Style',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 16),
          _buildStyleSelection(tripProvider, draft),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        Row(
          children: [
            _buildCounterButton(Icons.remove, () => value > 1 ? onChanged(value - 1) : null),
            const SizedBox(width: 20),
            Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            _buildCounterButton(Icons.add, () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onTap == null ? const Color(0xFFD1D5DB) : const Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildStyleSelection(TripProvider provider, Trip draft) {
    return Column(
      children: TravelStyle.values.map((style) {
        final isSelected = draft.travelStyle == style;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => provider.updateDraft(draft.copyWith(travelStyle: style)),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    _getStyleIcon(style),
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.name[0].toUpperCase() + style.name.substring(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF374151),
                          ),
                        ),
                        Text(
                          _getStyleDesc(style),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getStyleIcon(TravelStyle style) {
    switch (style) {
      case TravelStyle.budget: return Icons.savings;
      case TravelStyle.standard: return Icons.flight;
      case TravelStyle.luxury: return Icons.hotel;
    }
  }

  String _getStyleDesc(TravelStyle style) {
    switch (style) {
      case TravelStyle.budget: return 'Value for money and authentic experiences.';
      case TravelStyle.standard: return 'Comfortable stays and key highlights.';
      case TravelStyle.luxury: return 'Premium amenities and exclusive services.';
    }
  }
}
