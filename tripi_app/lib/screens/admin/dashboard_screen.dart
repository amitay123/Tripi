import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/tripi_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          NetworkImage('https://i.pravatar.cc/150?u=admin'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Console',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: TripiColors.primary,
                                  ),
                        ),
                        Text(
                          'GLOBAL TRAVEL OPS',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TripiColors.onSurfaceVariant
                                        .withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.notifications_none,
                      color: TripiColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Good evening, Amitay',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here's what's happening with your travel network today.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TripiColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            _buildTripNetworkOverview(context),
            const SizedBox(height: 24),
            _buildMarketReach(context),
            const SizedBox(height: 24),
            _buildUsageOverTime(context),
            const SizedBox(height: 24),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTripNetworkOverview(BuildContext context) {
    final stats = MockDataService.adminStats;
    return TripiCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded,
                  color: TripiColors.primary.withOpacity(0.5)),
              const SizedBox(width: 12),
              Text(
                'Trip Network Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('45,802', 'TOTAL TRIPS'),
              _buildStatItem('1,204', 'ACTIVE TRIPS'),
              _buildStatItem('+18.2%', 'MONTHLY GROWTH', isPositive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {bool isPositive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : TripiColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: TripiColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketReach(BuildContext context) {
    return TripiCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MARKET REACH',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: TripiColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          const Text('Top Destinations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              const SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.72,
                      strokeWidth: 12,
                      backgroundColor: TripiColors.surfaceContainerLow,
                      color: TripiColors.primary,
                    ),
                    Text('72%',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.blue, 'Europe (45%)'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.lightBlueAccent, 'Asia (27%)'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.grey.shade300, 'Others (28%)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: TripiColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildUsageOverTime(BuildContext context) {
    return TripiCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PLATFORM PERFORMANCE',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: TripiColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Usage Over Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildToggleButton('7 Days', false),
                  const SizedBox(width: 8),
                  _buildToggleButton('30 Days', true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(10, (index) {
                final height =
                    [40, 60, 50, 80, 120, 100, 90, 110, 70, 60][index];
                final isHighlight = index == 4;
                return Container(
                  width: 20,
                  height: height.toDouble(),
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? TripiColors.primary
                        : TripiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isSelected ? TripiColors.primary : TripiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : TripiColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return TripiCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.history,
                  color: TripiColors.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 24),
          ...MockDataService.recentActivity
              .map((activity) => _buildActivityItem(activity)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: TripiColors.primary.withOpacity(0.1)),
            ),
            child: const Text('View All Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityLog activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
              radius: 18,
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?u=sarah')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: TripiColors.onSurface, fontSize: 13),
                    children: [
                      TextSpan(
                          text: activity.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: TripiColors.primary)),
                      const TextSpan(text: ' '),
                      TextSpan(text: activity.action),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(activity.timeAgo,
                    style: const TextStyle(
                        fontSize: 11, color: TripiColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
