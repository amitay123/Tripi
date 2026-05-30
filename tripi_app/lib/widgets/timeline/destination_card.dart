import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/timeline_models.dart';
import '../../providers/timeline_provider.dart';
import '../../theme/tripi_colors.dart';

class DestinationCard extends StatelessWidget {
  final DestinationInsight insight;

  const DestinationCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimelineProvider>();
    final isSelected =
        provider.selectedInsight?.destination.id == insight.destination.id;
    final reasons = (insight.recommendationScores['reasons'] as List?)
            ?.map((reason) => reason.toString())
            .where((reason) => reason.trim().isNotEmpty)
            .take(3)
            .toList() ??
        const <String>[];

    return GestureDetector(
      onTap: () {
        provider.selectDestination(insight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: TripiColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  insight.destination.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Top badges
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          insight.popularity.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Destination Info
                    Text(
                      insight.destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      insight.destination.country,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Insights Row
                    Row(
                      children: [
                        _buildMiniBadge(Icons.flight,
                            '\$${insight.flightData.averagePrice.toInt()} avg'),
                        const SizedBox(width: 8),
                        _buildMiniBadge(Icons.wb_sunny,
                            '${insight.weatherData.averageHigh.toInt()}°C'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (reasons.isNotEmpty) ...[
                      ...reasons.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildReasonPill(reason),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // AI Insight Text
                    Text(
                      insight.aiInsight,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonPill(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
