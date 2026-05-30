import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/timeline_models.dart';
import '../../services/timeline/airport_catalog.dart';
import '../../theme/tripi_colors.dart';
import '../../widgets/timeline/smart_calendar.dart';
import '../../widgets/timeline/destination_card.dart';
import '../../widgets/timeline/flight_insights.dart';
import '../../widgets/timeline/hotel_insights.dart';
import '../../services/mock_data_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TimelineProvider>();
      await provider.loadTravelContext();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? TripiColors.darkBackground : TripiColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(isDark),
              _buildUpcomingTripsStrip(isDark),
              _buildTravelContextStrip(isDark),
              _buildCalendarSection(isDark),
              _buildDynamicContent(isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan your next adventure',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── UPCOMING TRIPS STRIP ─────────────────────────────────────────────────

  Widget _buildUpcomingTripsStrip(bool isDark) {
    return SliverToBoxAdapter(
      child: Consumer<TripProvider>(
        builder: (context, tripProvider, _) {
          final now = DateTime.now();
          final upcoming = tripProvider.trips
              .where((t) =>
                  !t.isCompleted &&
                  t.startDate.isAfter(now) &&
                  t.deletedAt == null)
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          if (upcoming.isEmpty) return const SizedBox(height: 16);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'Upcoming Trips',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: upcoming.length,
                  itemBuilder: (ctx, i) {
                    final trip = upcoming[i];
                    final daysUntil = trip.startDate.difference(now).inDays;
                    final img = MockDataService.getDestinationImage(
                        trip.city, trip.country);
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(img, fit: BoxFit.cover),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.0),
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    trip.city ?? trip.country,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    daysUntil == 0
                                        ? 'Today!'
                                        : 'in $daysUntil days',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── TRAVEL CONTEXT STRIP ──────────────────────────────────────────────────

  Widget _buildTravelContextStrip(bool isDark) {
    return SliverToBoxAdapter(
      child: Consumer<TimelineProvider>(
        builder: (context, provider, _) {
          final intent = provider.travelIntent;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'Travel Context',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildContextChip(
                      icon: Icons.flight_takeoff_rounded,
                      label: intent.originAirport?.iataCode ?? 'Origin',
                      isDark: isDark,
                      onTap: () => _showOriginSheet(context, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildContextChip(
                      icon: Icons.people_rounded,
                      label: _travelersLabel(intent),
                      isDark: isDark,
                      onTap: () => _showCompanionsSheet(context, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildContextChip(
                      icon: Icons.luggage_rounded,
                      label: _purposeLabel(intent.purpose),
                      isDark: isDark,
                      onTap: () => _showEnumSheet<TravelPurpose>(
                        context: context,
                        provider: provider,
                        title: 'Trip Purpose',
                        values: TravelPurpose.values,
                        currentValue: intent.purpose,
                        getName: _purposeLabel,
                        onSelected: (val) => provider
                            .updateTravelIntent(intent.copyWith(purpose: val)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildContextChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: _budgetLabel(intent.budgetPreference),
                      isDark: isDark,
                      onTap: () => _showEnumSheet<BudgetType>(
                        context: context,
                        provider: provider,
                        title: 'Budget Level',
                        values: BudgetType.values,
                        currentValue: intent.budgetPreference,
                        getName: _budgetLabel,
                        onSelected: (val) => provider.updateTravelIntent(
                            intent.copyWith(budgetPreference: val)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildContextChip(
                      icon: Icons.chair_rounded,
                      label: intent.cabinClass.name.capitalize(),
                      isDark: isDark,
                      onTap: () => _showEnumSheet<CabinClass>(
                        context: context,
                        provider: provider,
                        title: 'Cabin Class',
                        values: CabinClass.values,
                        currentValue: intent.cabinClass,
                        getName: _cabinLabel,
                        onSelected: (val) => provider.updateTravelIntent(
                            intent.copyWith(cabinClass: val)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildContextChip(
                      icon: Icons.calendar_month_rounded,
                      label:
                          intent.isFlexibleDates ? 'Flexible' : 'Exact Dates',
                      isDark: isDark,
                      isActive: intent.isFlexibleDates,
                      onTap: () {
                        provider.updateTravelIntent(
                          intent.copyWith(
                              isFlexibleDates: !intent.isFlexibleDates),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final bgColor = isActive
        ? TripiColors.primary.withValues(alpha: 0.15)
        : (isDark ? TripiColors.surfaceContainerHigh : Colors.white);
    final borderColor = isActive
        ? TripiColors.primary.withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF2C3238) : TripiColors.outlineVariant);
    final textColor = isActive
        ? TripiColors.primary
        : (isDark ? Colors.white70 : Colors.black87);
    final iconColor = isActive
        ? TripiColors.primary
        : (isDark ? Colors.white54 : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnumSheet<T>({
    required BuildContext context,
    required TimelineProvider provider,
    required String title,
    required List<T> values,
    required T currentValue,
    required String Function(T) getName,
    required void Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? TripiColors.darkBackground : TripiColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...values.map((v) {
                final isSelected = v == currentValue;
                return InkWell(
                  onTap: () {
                    onSelected(v);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TripiColors.primary.withValues(alpha: 0.1)
                          : (isDark
                              ? TripiColors.surfaceContainerHigh
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? TripiColors.primary.withValues(alpha: 0.5)
                            : (isDark
                                ? const Color(0xFF2C3238)
                                : TripiColors.outlineVariant),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getName(v),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? TripiColors.primary
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: TripiColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _showOriginSheet(
    BuildContext context,
    TimelineProvider provider, {
    bool isInitialPrompt = false,
  }) {
    var query = '';
    var results = AirportCatalog.search(query).take(10).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? TripiColors.darkBackground
                        : TripiColors.background,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Departure Airport',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isInitialPrompt) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Choose once for sharper flight suggestions.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search airport, city, country, or IATA',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: isDark
                              ? TripiColors.surfaceContainerHigh
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2C3238)
                                  : TripiColors.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: TripiColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                            results =
                                AirportCatalog.search(query).take(10).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? TripiColors.surfaceContainerHigh
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C3238)
                                  : TripiColors.outlineVariant,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: results.isEmpty
                              ? Center(
                                  child: Text(
                                    'No airports found',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: results.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: isDark
                                        ? const Color(0xFF2C3238)
                                        : TripiColors.outlineVariant,
                                  ),
                                  itemBuilder: (context, index) {
                                    final airport = results[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: TripiColors.primary
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                          airport.iataCode,
                                          style: const TextStyle(
                                            color: TripiColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        airport.airportName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${airport.city}, ${airport.country}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                      onTap: () {
                                        provider.updateTravelIntent(
                                          provider.travelIntent.copyWith(
                                            originAirport: airport,
                                          ),
                                        );
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      if (!isInitialPrompt &&
                          provider.travelIntent.originAirport != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            provider.updateTravelIntent(
                              provider.travelIntent.copyWith(
                                clearOriginAirport: true,
                              ),
                              clearOrigin: true,
                            );
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Remove saved airport'),
                        ),
                      ],
                      SizedBox(height: MediaQuery.of(ctx).padding.bottom),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCompanionsSheet(BuildContext context, TimelineProvider provider) {
    int adults = provider.travelIntent.adults;
    List<int?> childAges = List<int?>.from(provider.travelIntent.childAges);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color:
                  isDark ? TripiColors.darkBackground : TripiColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Travel Companions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                _buildCounterRow(
                  label: 'Adults',
                  value: adults,
                  isDark: isDark,
                  minValue: 1,
                  onChanged: (value) => setState(() => adults = value),
                ),
                const SizedBox(height: 16),
                _buildCounterRow(
                  label: 'Children',
                  value: childAges.length,
                  isDark: isDark,
                  minValue: 0,
                  onChanged: (value) {
                    setState(() {
                      if (value > childAges.length) {
                        childAges.addAll(
                          List<int?>.filled(value - childAges.length, null),
                        );
                      } else {
                        childAges = childAges.take(value).toList();
                      }
                    });
                  },
                ),
                if (childAges.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Child ages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(childAges.length, (index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? TripiColors.surfaceContainerHigh
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2C3238)
                                : TripiColors.outlineVariant,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: childAges[index],
                            hint: Text(
                              'Child ${index + 1}: Age',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(14),
                            dropdownColor: isDark
                                ? TripiColors.surfaceContainerHigh
                                : Colors.white,
                            items: List.generate(
                              18,
                              (age) => DropdownMenuItem<int>(
                                value: age,
                                child: Text(
                                  'Child ${index + 1}: $age',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (age) {
                              if (age == null) return;
                              setState(() => childAges[index] = age);
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 32),
                if (childAges.any((age) => age == null)) ...[
                  Text(
                    'Add an age for each child to continue.',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: childAges.any((age) => age == null)
                        ? null
                        : () {
                            provider.updateTravelIntent(
                              provider.travelIntent.copyWith(
                                adults: adults,
                                childAges: childAges.whereType<int>().toList(),
                              ),
                            );
                            Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TripiColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required bool isDark,
    required int minValue,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? TripiColors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3238) : TripiColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: value > minValue ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: TripiColors.primary,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: TripiColors.primary,
          ),
        ],
      ),
    );
  }

  // ─── CALENDAR SECTION ─────────────────────────────────────────────────────

  Widget _buildCalendarSection(bool isDark) {
    return SliverToBoxAdapter(
      child: Consumer<TimelineProvider>(
        builder: (context, provider, _) {
          final hasRange = provider.hasSelectedRange;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (hasRange)
                      GestureDetector(
                        onTap: () => provider.clearSelection(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: TripiColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: TripiColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Selected range summary chip
              if (hasRange) _buildRangeSummaryChip(provider, isDark),
              // Calendar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SmartCalendar(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeSummaryChip(TimelineProvider provider, bool isDark) {
    final start = provider.selectedStartDate!;
    final end = provider.selectedEndDate!;
    final days = provider.selectedDurationDays ?? 0;
    final fmt = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: TripiColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: TripiColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: TripiColors.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              '${fmt.format(start)} → ${fmt.format(end)}',
              style: const TextStyle(
                color: TripiColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TripiColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$days nights',
                style: const TextStyle(
                  color: TripiColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DYNAMIC CONTENT ──────────────────────────────────────────────────────

  Widget _buildDynamicContent(bool isDark) {
    return SliverToBoxAdapter(
      child: Consumer<TimelineProvider>(
        builder: (context, provider, _) {
          if (provider.shouldShowOriginPrompt) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !provider.shouldShowOriginPrompt) return;
              provider.markOriginPromptShown();
              _showOriginSheet(context, provider, isInitialPrompt: true);
            });
          }
          if (provider.hasSelectedRange && provider.isLoadingTravelContext) {
            return _buildContextLoadingState(isDark);
          }
          if (!provider.hasSelectedRange) {
            return _buildEmptyState(provider, isDark);
          }
          if (provider.isLoadingInsights) {
            return _buildLoadingState(isDark);
          }
          if (provider.selectedInsight != null) {
            return _buildInsightDetail(provider, isDark);
          }
          if (provider.recommendedInsights.isNotEmpty) {
            return _buildRecommendations(provider, isDark);
          }
          return _buildNoResults(provider, isDark);
        },
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(TimelineProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          if (provider.travelIntent.originAirport == null) ...[
            _buildOriginAccuracyPrompt(provider, isDark),
            const SizedBox(height: 24),
          ],
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: TripiColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_outlined,
                size: 32, color: TripiColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Tap a date to start planning',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a date range and we\'ll find\nthe best destinations for your trip',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          // Hint cards
          Row(
            children: [
              _buildHintCard(Icons.flight_takeoff, 'Flight\nPrices', isDark),
              const SizedBox(width: 12),
              _buildHintCard(
                  Icons.wb_sunny_outlined, 'Weather\nInsights', isDark),
              const SizedBox(width: 12),
              _buildHintCard(Icons.hotel_outlined, 'Hotel\nTrends', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? TripiColors.darkSurfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? const Color(0xFF2C3238) : TripiColors.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: TripiColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOADING STATE ────────────────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: TripiColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding the best destinations...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing flights, hotels & weather',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? TripiColors.darkSurfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? const Color(0xFF2C3238) : TripiColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: TripiColors.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading your saved travel context...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RECOMMENDATIONS ──────────────────────────────────────────────────────

  Widget _buildRecommendations(TimelineProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.travelIntent.originAirport == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildOriginAccuracyPrompt(provider, isDark),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: TripiColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recommended Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
          child: Text(
            'Based on your dates and travel context',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ),
        SizedBox(
          height: 410,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: provider.recommendedInsights.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + index * 100),
                curve: Curves.easeOutCubic,
                builder: (ctx, val, child) => Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - val)),
                    child: child,
                  ),
                ),
                child: DestinationCard(
                  insight: provider.recommendedInsights[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── INSIGHT DETAIL ───────────────────────────────────────────────────────

  Widget _buildInsightDetail(TimelineProvider provider, bool isDark) {
    final insight = provider.selectedInsight!;
    final start = provider.selectedStartDate!;
    final end = provider.selectedEndDate!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button + title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => provider.selectDestination(null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? TripiColors.darkSurfaceContainerLow
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C3238)
                          : TripiColors.outlineVariant,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.destination.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      insight.destination.country,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Hero image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildHeroImage(insight, isDark),
        ),
        const SizedBox(height: 20),
        // Quick stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildQuickStats(insight, isDark),
        ),
        const SizedBox(height: 24),
        // AI Insight box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildAiInsightBox(insight, isDark),
        ),
        const SizedBox(height: 20),
        // Flight Insights
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FlightInsights(
            insight: insight,
            startDate: start,
            endDate: end,
          ),
        ),
        // Hotel Insights
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: HotelInsights(insight: insight),
        ),
      ],
    );
  }

  Widget _buildHeroImage(DestinationInsight insight, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              insight.destination.imageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      insight.destination.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DestinationInsight insight, bool isDark) {
    final stats = [
      (
        Icons.flight_takeoff_rounded,
        '\$${insight.flightData.averagePrice.toInt()}',
        'Avg. Flight',
        TripiColors.primary
      ),
      (
        Icons.wb_sunny_rounded,
        '${insight.weatherData.averageHigh.toInt()}°C',
        'Avg. High',
        const Color(0xFFF59E0B)
      ),
      (
        Icons.hotel_rounded,
        '\$${insight.hotelData.averagePricePerNight.toInt()}/night',
        'Hotel',
        const Color(0xFF10B981)
      ),
      (
        Icons.people_rounded,
        insight.crowdLevels.capitalize(),
        'Crowds',
        const Color(0xFF8B5CF6)
      ),
    ];

    return Row(
      children: stats.map((s) {
        final (icon, value, label, color) = s;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: stats.indexOf(s) < stats.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color:
                  isDark ? TripiColors.darkSurfaceContainerLow : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2C3238)
                    : TripiColors.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAiInsightBox(DestinationInsight insight, bool isDark) {
    if (insight.aiInsight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TripiColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TripiColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TripiColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: TripiColors.primary, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.aiInsight,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginAccuracyPrompt(TimelineProvider provider, bool isDark) {
    return GestureDetector(
      onTap: () => _showOriginSheet(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TripiColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TripiColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flight_takeoff_rounded,
              color: TripiColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add your departure airport for more accurate flight suggestions.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TripiColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _travelersLabel(TravelIntent intent) {
    final adults = '${intent.adults} Adult${intent.adults == 1 ? '' : 's'}';
    if (intent.children == 0) return adults;
    return '$adults · ${intent.children} Child${intent.children == 1 ? '' : 'ren'}';
  }

  String _purposeLabel(TravelPurpose purpose) {
    switch (purpose) {
      case TravelPurpose.relaxation:
        return 'Relaxation';
      case TravelPurpose.romantic:
        return 'Romantic';
      case TravelPurpose.adventure:
        return 'Adventure';
      case TravelPurpose.culture:
        return 'Culture';
      case TravelPurpose.food:
        return 'Food';
      case TravelPurpose.nightlife:
        return 'Nightlife';
      case TravelPurpose.shopping:
        return 'Shopping';
      case TravelPurpose.nature:
        return 'Nature';
      case TravelPurpose.familyFriendly:
        return 'Family Friendly';
      case TravelPurpose.workation:
        return 'Workation';
    }
  }

  String _budgetLabel(BudgetType budget) {
    switch (budget) {
      case BudgetType.budget:
        return 'Budget';
      case BudgetType.midRange:
        return 'Mid-range';
      case BudgetType.luxury:
        return 'Luxury';
      case BudgetType.flexible:
        return 'Flexible';
    }
  }

  String _cabinLabel(CabinClass cabinClass) {
    switch (cabinClass) {
      case CabinClass.economy:
        return 'Economy';
      case CabinClass.premiumEconomy:
        return 'Premium Economy';
      case CabinClass.business:
        return 'Business';
      case CabinClass.first:
        return 'First';
    }
  }

  Widget _buildNoResults(TimelineProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          if (provider.travelIntent.originAirport == null) ...[
            _buildOriginAccuracyPrompt(provider, isDark),
            const SizedBox(height: 24),
          ],
          Center(
            child: Text(
              'No recommendations found.\nTry different dates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
