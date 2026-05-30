import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/timeline_models.dart';
import '../../providers/timeline_provider.dart';
import '../../services/timeline/skyscanner_deep_link_service.dart';
import '../../theme/tripi_colors.dart';

class FlightInsights extends StatelessWidget {
  final DestinationInsight insight;
  final DateTime startDate;
  final DateTime endDate;

  const FlightInsights({
    super.key,
    required this.insight,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flightData = insight.flightData;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? TripiColors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TripiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flight_takeoff, color: TripiColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Flight Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Insight Badges
          Row(
            children: [
              _buildTrendBadge(
                flightData.priceTrend == 'down' ? Icons.trending_down : Icons.trending_up, 
                'Prices trending ${flightData.priceTrend}', 
                flightData.priceTrend == 'down' ? Colors.green : Colors.orange,
              ),
              if (flightData.bestTimeToBook != null) ...[
                const SizedBox(width: 8),
                _buildTrendBadge(Icons.event_available, flightData.bestTimeToBook!, TripiColors.primary),
              ]
            ],
          ),
          const SizedBox(height: 20),

          // Flight Option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? TripiColors.surfaceContainerHigh : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Value',
                      style: TextStyle(
                        fontSize: 12,
                        color: TripiColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct • ${flightData.directFlightCount} options',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${flightData.averagePrice.toInt()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final intent = context.read<TimelineProvider>().travelIntent;
                if (intent.originAirport == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add your departure airport for accurate flight results.',
                      ),
                    ),
                  );
                  return;
                }
                final destinationAirportIata =
                    SkyscannerDeepLinkService.destinationAirportIata(
                  destinationName: insight.destination.name,
                  country: insight.destination.country,
                );
                SkyscannerDeepLinkService.launchFlightSearch(
                  originAirportIata: intent.origin,
                  destinationAirportIata: destinationAirportIata,
                  departureDate: startDate,
                  returnDate: endDate,
                  adults: intent.adults,
                  children: intent.children,
                  childAges: intent.childAges,
                  cabinClass: intent.cabinClass.name,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: TripiColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Check Flights on Skyscanner',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
