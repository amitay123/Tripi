import 'package:flutter/material.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: TripiColors.background,
        elevation: 0,
        title: const Text('Paris Itinerary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TripiColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DAY 01', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TripiColors.primary, letterSpacing: 2)),
            const SizedBox(height: 16),
            _buildActivityItem(context, '09:00', 'Coffee at Café de Flore', 'Start your day like a Parisian.'),
            _buildActivityItem(context, '11:00', 'Louvre Museum', 'Explore the world\'s largest art museum.'),
            const SizedBox(height: 32),
            Text('DAY 02', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TripiColors.primary, letterSpacing: 2)),
            const SizedBox(height: 16),
            _buildActivityItem(context, '10:00', 'Eiffel Tower', 'A morning ascent to see the city.'),
            _buildActivityItem(context, '13:00', 'Lunch at Le Jules Verne', 'High-end dining with a view.'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String time, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TripiCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
