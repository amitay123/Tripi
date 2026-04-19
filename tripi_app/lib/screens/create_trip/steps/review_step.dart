import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/trip_provider.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

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
            'Ready to go?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your trip details before creating.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildSummaryCard(
            'Basic Info',
            [
              _buildDetail('Trip Name', draft.name),
              _buildDetail('Destination', '${draft.city ?? ''}, ${draft.country}'.trim().replaceAll(RegExp(r'^,\s*'), '')),
              _buildDetail('Type', draft.tripType.name[0].toUpperCase() + draft.tripType.name.substring(1)),
            ],
            () => tripProvider.goToStep(0),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Schedule',
            [
              _buildDetail('Dates', '${DateFormat('MMM dd').format(draft.startDate)} - ${DateFormat('MMM dd, yyyy').format(draft.endDate)}'),
              _buildDetail('Duration', '${draft.durationDays} Days'),
            ],
            () => tripProvider.goToStep(1),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Travelers & Style',
            [
              _buildDetail('People', '${draft.travelersCount} Travelers'),
              _buildDetail('Style', draft.travelStyle.name[0].toUpperCase() + draft.travelStyle.name.substring(1)),
            ],
            () => tripProvider.goToStep(2),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Budget',
            [
              _buildDetail('Total', '${draft.currency} ${draft.budgetTotal ?? 'Not set'}'),
              if (draft.budgetTotal != null) _buildDetail('Daily', '${draft.currency} ${draft.budgetDaily?.toStringAsFixed(0)}'),
            ],
            () => tripProvider.goToStep(3),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Preferences',
            [
              _buildDetail('Goals', draft.preferences.isEmpty ? 'None' : draft.preferences.join(', ')),
              _buildDetail('Pace', draft.pace.name[0].toUpperCase() + draft.pace.name.substring(1)),
            ],
            () => tripProvider.goToStep(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> details, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              InkWell(
                onTap: onEdit,
                child: const Text('Edit', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}
