import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/models.dart';
import '../../theme/tripi_colors.dart';

class SmartCalendar extends StatefulWidget {
  const SmartCalendar({super.key});

  @override
  State<SmartCalendar> createState() => _SmartCalendarState();
}

class _SmartCalendarState extends State<SmartCalendar> {
  late PageController _pageController;
  late DateTime _currentMonth;
  final int _initialPage = 1200;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      final monthOffset = index - _initialPage;
      final now = DateTime.now();
      _currentMonth = DateTime(now.year, now.month + monthOffset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timelineProvider = context.watch<TimelineProvider>();
    final tripProvider = context.watch<TripProvider>();
    final trips = tripProvider.trips;
    final overlappingTrip = timelineProvider.getOverlappingTrip(trips);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? TripiColors.darkSurfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3238) : TripiColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthHeader(isDark),
          _buildWeekdayRow(isDark),
          const SizedBox(height: 4),
          SizedBox(
            height: 270,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final monthOffset = index - _initialPage;
                final now = DateTime.now();
                final monthDate =
                    DateTime(now.year, now.month + monthOffset, 1);
                return _buildMonthGrid(
                    context, monthDate, timelineProvider, trips, isDark);
              },
            ),
          ),
          if (overlappingTrip != null) _buildOverlapWarning(overlappingTrip),
          const SizedBox(height: 8),
          _buildLegend(isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              _buildNavBtn(Icons.chevron_left_rounded, () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }, isDark),
              _buildNavBtn(Icons.chevron_right_rounded, () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isDark
              ? TripiColors.darkBackground
              : TripiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: isDark ? Colors.white70 : const Color(0xFF374151)),
      ),
    );
  }

  Widget _buildWeekdayRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
          return SizedBox(
            width: 38,
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime monthDate,
    TimelineProvider provider,
    List<dynamic> trips,
    bool isDark,
  ) {
    final daysInMonth =
        DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstDayOffset = monthDate.weekday % 7;
    const totalCells = 42;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstDayOffset ||
            index >= firstDayOffset + daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = index - firstDayOffset + 1;
        final date = DateTime(monthDate.year, monthDate.month, day);
        final now = DateTime.now();
        final today =
            DateTime(now.year, now.month, now.day);
        final isToday = date == today;
        final isPast = date.isBefore(today);

        // Selection
        final isStart = provider.selectedStartDate != null &&
            DateUtils.isSameDay(date, provider.selectedStartDate);
        final isEnd = provider.selectedEndDate != null &&
            DateUtils.isSameDay(date, provider.selectedEndDate);
        final isMid = provider.selectedStartDate != null &&
            provider.selectedEndDate != null &&
            date.isAfter(provider.selectedStartDate!) &&
            date.isBefore(provider.selectedEndDate!);

        // Trips
        Trip? activeTrip;
        bool isTripStart = false;
        bool isTripEnd = false;

        for (final t in trips) {
          if (t is Trip) {
            final tS = DateTime(
                t.startDate.year, t.startDate.month, t.startDate.day);
            final tE =
                DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
            if (DateUtils.isSameDay(date, tS)) {
              activeTrip = t;
              isTripStart = true;
              isTripEnd = DateUtils.isSameDay(date, tE);
            } else if (DateUtils.isSameDay(date, tE)) {
              activeTrip = t;
              isTripEnd = true;
            } else if (date.isAfter(tS) && date.isBefore(tE)) {
              activeTrip = t;
            }
          }
        }

        final isSelected = isStart || isEnd || isMid;
        final isTrip = activeTrip != null;
        final tripColor = (activeTrip?.isCompleted == true)
            ? Colors.grey
            : TripiColors.primary;

        return GestureDetector(
          onTap: () {
            if (!isPast) provider.selectDate(date);
          },
          child: Stack(
            children: [
              // Trip range background
              if (isTrip && !isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: tripColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.horizontal(
                        left: isTripStart
                            ? const Radius.circular(20)
                            : Radius.zero,
                        right:
                            isTripEnd ? const Radius.circular(20) : Radius.zero,
                      ),
                    ),
                  ),
                ),

              // Selection range background
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: TripiColors.primary.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.horizontal(
                        left: isStart
                            ? const Radius.circular(20)
                            : Radius.zero,
                        right:
                            isEnd ? const Radius.circular(20) : Radius.zero,
                      ),
                    ),
                  ),
                ),

              // Day circle
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isStart || isEnd)
                        ? TripiColors.primary
                        : (isTripStart || isTripEnd) && !isSelected
                            ? tripColor.withValues(alpha: 0.85)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday &&
                            !isStart &&
                            !isEnd &&
                            !isTripStart &&
                            !isTripEnd
                        ? Border.all(color: TripiColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isStart || isEnd || isTripStart || isTripEnd)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: (isStart || isEnd)
                            ? Colors.white
                            : (isTripStart || isTripEnd) && !isSelected
                                ? Colors.white
                                : isPast
                                    ? (isDark
                                        ? Colors.white24
                                        : Colors.black26)
                                    : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverlapWarning(Trip trip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Overlaps with "${trip.name}"',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _legendDot(TripiColors.primary),
          const SizedBox(width: 6),
          Text('Your trips',
              style: TextStyle(
                  fontSize: 11,
                  color:
                      isDark ? Colors.white54 : const Color(0xFF6B7280))),
          const SizedBox(width: 16),
          _legendDot(TripiColors.primary.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text('Selected range',
              style: TextStyle(
                  fontSize: 11,
                  color:
                      isDark ? Colors.white54 : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
