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
            'Review your trip',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Double check everything before we start planning your itinerary.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildSummaryCard(
            'Basic Identity',
            [
              _buildDetail('Trip Name', draft.name),
              _buildDetail('Destination', '${draft.city ?? ''}, ${draft.country}'.trim().replaceAll(RegExp(r'^,\s*'), '')),
            ],
            () => tripProvider.goToStep(0),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Time & People',
            [
              _buildDetail('Dates', '${DateFormat('MMM dd').format(draft.startDate)} - ${DateFormat('MMM dd, yyyy').format(draft.endDate)}'),
              _buildDetail('Duration', '${draft.durationDays} Days'),
              _buildDetail('Travelers', '${draft.travelersCount} Adults'),
            ],
            () => tripProvider.goToStep(1),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Style & Vibe',
            [
              _buildDetail('Trip Type', draft.tripType.name[0].toUpperCase() + draft.tripType.name.substring(1)),
              _buildDetail('Goals', draft.preferences.isEmpty ? 'General' : draft.preferences.join(', ')),
              _buildDetail('Pace', draft.pace.name[0].toUpperCase() + draft.pace.name.substring(1)),
            ],
            () => tripProvider.goToStep(2),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Your trip is ready to be created! We will generate a custom itinerary for you in the next step.',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> details, VoidCallback onEdit) {
    return Container(
      width: double.infinity,
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
              Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563), fontSize: 11, letterSpacing: 0.5)),
              InkWell(
                onTap: onEdit,
                child: const Text('Edit', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

