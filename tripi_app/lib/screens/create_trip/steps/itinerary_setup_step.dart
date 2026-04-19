import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';

class ItinerarySetupStep extends StatelessWidget {
  const ItinerarySetupStep({super.key});

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
            'Initial Setup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some must-see places to your itinerary.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search places in ${draft.country}...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Suggested for you',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 16),
          _buildSuggestionItem('Local Landmark', 'A historical site with a great view.'),
          _buildSuggestionItem('Hidden Gem', 'A quiet spot known by locals.'),
          _buildSuggestionItem('Fine Dining', 'Exquisite cuisine and atmosphere.'),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () => tripProvider.nextStep(),
              child: const Text('SKIP FOR NOW', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.place, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB))),
          ],
        ),
      ),
    );
  }
}
