import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../providers/booking_provider.dart';
import '../models/models.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final itinerary = provider.itinerary;

    if (itinerary == null) {
      return const Scaffold(
        body: Center(child: Text('No itinerary found')),
      );
    }

    return Scaffold(
      backgroundColor: TripiColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, itinerary),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, itinerary),
                  const SizedBox(height: 32),
                  _buildDayTabs(context, provider),
                  const SizedBox(height: 24),
                  _buildTimeline(context, provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (picked != null) {
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (context.mounted) {
        context
            .read<TripProvider>()
            .updateDayStartTime(trip.id, day.dayIndex, formattedTime);
      }
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Widget _buildActivityItem(BuildContext context, Trip trip, TripDay day,
      Activity activity, int index, String arrivalTime,
      {required Key key}) {
    return Column(
      key: key,
      children: [
        // Item 2: Transport picker MOVED to timeline
        if (index > 0)
          _buildTimelineTransportDivider(context, trip, day, activity),
        Dismissible(
          key: Key('dismiss_${activity.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context
                .read<TripProvider>()
                .deleteActivity(trip.id, day.dayIndex, activity.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Column
                SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      // Item 1: Icon changes based on category
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(activity),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(_getCategoryIcon(activity),
                            color: _getCategoryIconColor(activity), size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(activity.duration),
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TripiCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              child: Image.network(
                                activity.imageUrl!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        arrivalTime,
                                        style: const TextStyle(
                                            color: TripiColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activity.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1E293B)),
                                      ),
                                      if (activity.address != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            activity.address!,
                                            style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () {
                                          if (activity.placeId != null) {
                                            Navigator.pushNamed(
                                              context,
                                              '/place-details',
                                              arguments: activity.placeId,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Details not available for this activity')),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            'View Details →',
                                            style: TextStyle(
                                                color: TripiColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.drag_handle,
                                        color: Color(0xFFCBD5E1), size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, Itinerary itinerary) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: TripiColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              itinerary.imageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Itinerary itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TripiColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'MY TRIP',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: TripiColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          itinerary.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: TripiColors.onSurface,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: TripiColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              '${itinerary.days.length} Days',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TripiColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.location_on_outlined, size: 16, color: TripiColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              itinerary.location,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TripiColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayTabs(BuildContext context, BookingProvider provider) {
    final itinerary = provider.itinerary!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: itinerary.days.map((day) {
          final isSelected = provider.selectedDayIndex == day.dayNumber - 1;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => provider.setSelectedDay(day.dayNumber - 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? TripiColors.primary : TripiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Day ${day.dayNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : TripiColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, BookingProvider provider) {
    final day = provider.itinerary!.days[provider.selectedDayIndex];
    return Column(
      children: day.activities.map((activity) {
        return _ActivityItem(
          activity: activity,
          isLast: day.activities.last == activity,
        );
      }).toList(),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: TripiColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: TripiColors.primary.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'View Interactive Map',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Activity activity;
  final bool isLast;

  const _ActivityItem({
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineIndicator(),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildActivityCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: TripiColors.primary, width: 6),
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              color: TripiColors.outlineVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return TripiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activity.time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TripiColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TripiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TripiColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activity.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TripiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TripiColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (activity.travelMode != null) ...[
            const SizedBox(height: 16),
            _buildTravelIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TripiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            activity.travelMode == 'Walk' ? Icons.directions_walk : Icons.directions_car,
            size: 16,
            color: TripiColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '${activity.travelMode} • ${activity.travelTime}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TripiColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
