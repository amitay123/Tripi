import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../models/models.dart';

class BasicInfoStep extends StatelessWidget {
  const BasicInfoStep({super.key});

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
            'Tell us about your trip',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Every great adventure needs a name.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildLabel('Trip Name'),
          TextField(
            onChanged: (val) => tripProvider.updateDraft(draft.copyWith(name: val)),
            decoration: _inputDecoration('e.g. European Summer 2024'),
            controller: TextEditingController(text: draft.name)..selection = TextSelection.collapsed(offset: draft.name.length),
          ),
          const SizedBox(height: 24),
          _buildLabel('Where are you going?'),
          TextField(
            onChanged: (val) => tripProvider.updateDraft(draft.copyWith(country: val)),
            decoration: _inputDecoration('Country (Required)'),
            controller: TextEditingController(text: draft.country)..selection = TextSelection.collapsed(offset: draft.country.length),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => tripProvider.updateDraft(draft.copyWith(city: val)),
            decoration: _inputDecoration('City (Optional)'),
            controller: TextEditingController(text: draft.city ?? '')..selection = TextSelection.collapsed(offset: (draft.city ?? '').length),
          ),
          const SizedBox(height: 24),
          _buildLabel('Trip Type'),
          Wrap(
            spacing: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }

  String _formatEnum(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }
}
