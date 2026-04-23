import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';

class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final destination = context.watch<BookingProvider>().selectedDestination;

    if (destination == null) {
      return const Scaffold(
          body: Center(child: Text('No destination selected')));
    }

    return Scaffold(
      backgroundColor: TripiColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 450,
                  width: double.infinity,
                  color: TripiColors.surfaceContainerLow,
                  child: const Center(
                    child: Icon(Icons.image,
                        color: TripiColors.outlineVariant, size: 64),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        destination.country,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: TripiColors.onSurfaceVariant,
                                ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'ABOUT',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: TripiColors.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        destination.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'ITINERARY HIGHLIGHTS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: TripiColors.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildHighlightItem(context, '01', 'Artistic Mornings',
                          'Visit the world-renowned Louvre Museum.'),
                      _buildHighlightItem(context, '02', 'River Cruises',
                          'Experience the Seine at sunset.'),
                      const SizedBox(height: 120), // Space for FAB
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 48,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: TripiColors.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/flight-search');
              },
              child: const Text('Plan Trip & Book Flights'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(
      BuildContext context, String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: TripiColors.primary.withOpacity(0.2),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TripiColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
