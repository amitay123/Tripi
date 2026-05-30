import 'package:flutter/material.dart';
import '../../models/timeline_models.dart';
import '../../theme/tripi_colors.dart';

class HotelInsights extends StatelessWidget {
  final DestinationInsight insight;

  const HotelInsights({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hotelData = insight.hotelData;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hotel Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Hotel Info Row
          Row(
            children: [
              _buildInfoColumn('Avg Nightly', '\$${hotelData.averagePricePerNight.toInt()}', isDark),
              Container(
                width: 1,
                height: 40,
                color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildInfoColumn('Best Area', hotelData.bestNeighborhoods.isNotEmpty ? hotelData.bestNeighborhoods.first : 'Downtown', isDark),
              Container(
                width: 1,
                height: 40,
                color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildInfoColumn('Availability', hotelData.availabilityScore > 0.7 ? 'High' : 'Low', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
