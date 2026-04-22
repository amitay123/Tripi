import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/trip_provider.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import 'create_trip/add_activity_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class ItineraryScreen extends StatefulWidget {
  final String tripId;

  const ItineraryScreen({super.key, required this.tripId});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.trips.isNotEmpty 
        ? tripProvider.trips.firstWhere((t) => t.id == widget.tripId, orElse: () => tripProvider.trips.first)
        : null;

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('No trip found')));
    }

    return DefaultTabController(
      length: trip.days.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Text(trip.name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd').format(trip.endDate)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: TripiColors.primary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: TripiColors.primary,
            indicatorWeight: 3,
            tabs: trip.days.map((day) => Tab(text: 'Day ${day.dayIndex}')).toList(),
          ),
        ),
        body: TabBarView(
          children: trip.days.map((day) => _buildDayView(context, trip, day)).toList(),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Builder(
              builder: (context) => FloatingActionButton.small(
                heroTag: 'map_btn',
                onPressed: () {
                  final index = DefaultTabController.of(context).index;
                  _showFullMap(context, trip, trip.days[index]);
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.map, color: TripiColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) => FloatingActionButton(
                heroTag: 'add_btn',
                onPressed: () {
                  final index = DefaultTabController.of(context).index;
                  _showAddActivity(context, trip, trip.days[index]);
                },
                backgroundColor: TripiColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context, Trip trip, TripDay day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'Day ${day.dayIndex} Route Overview',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _getDayInitialLocation(day),
                        zoom: 12,
                      ),
                      markers: _createDayMarkers(day),
                      polylines: _createPolylines(day),
                      onMapCreated: (controller) {
                        _fitBounds(controller, day);
                      },
                      myLocationEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            Positioned(
              top: 20,
              right: 20,
              child: PointerInterceptor(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF1E293B), size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitBounds(GoogleMapController controller, TripDay day) {
    if (day.activities.isEmpty) return;
    
    final markers = day.activities.where((a) => a.lat != null && a.lng != null).toList();
    if (markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var m in markers) {
      if (minLat == null || m.lat! < minLat) minLat = m.lat;
      if (maxLat == null || m.lat! > maxLat) maxLat = m.lat;
      if (minLng == null || m.lng! < minLng) minLng = m.lng;
      if (maxLng == null || m.lng! > maxLng) maxLng = m.lng;
    }

    if (minLat != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng!),
        northeast: LatLng(maxLat!, maxLng!),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLng _getDayInitialLocation(TripDay day) {
    if (day.activities.isNotEmpty) {
      final firstWithLocation = day.activities.firstWhere(
        (a) => a.lat != null && a.lng != null,
        orElse: () => day.activities.first,
      );
      if (firstWithLocation.lat != null && firstWithLocation.lng != null) {
        return LatLng(firstWithLocation.lat!, firstWithLocation.lng!);
      }
    }
    return const LatLng(51.5074, -0.1278);
  }

  Set<Marker> _createDayMarkers(TripDay day) {
    Set<Marker> markers = {};
    for (int i = 0; i < day.activities.length; i++) {
      final activity = day.activities[i];
      if (activity.lat != null && activity.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(activity.id),
            position: LatLng(activity.lat!, activity.lng!),
            infoWindow: InfoWindow(
              title: '${i + 1}. ${activity.title}',
              snippet: activity.address,
            ),
          ),
        );
      }
    }
    return markers;
  }

  Set<Polyline> _createPolylines(TripDay day) {
    List<LatLng> points = [];
    for (var activity in day.activities) {
      if (activity.lat != null && activity.lng != null) {
        points.add(LatLng(activity.lat!, activity.lng!));
      }
    }

    if (points.length < 2) return {};

    return {
      Polyline(
        polylineId: PolylineId('route_day_${day.dayIndex}'),
        points: points,
        color: TripiColors.primary,
        width: 4,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Widget _buildDayView(BuildContext context, Trip trip, TripDay day) {
    final arrivalTimes = _calculateArrivalTimes(day);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd').format(day.date).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectStartTime(context, trip, day),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: TripiColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Starts at ${day.startTime}',
                          style: const TextStyle(
                            color: TripiColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.edit, size: 12, color: TripiColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${day.activities.length} items',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: day.activities.isEmpty
              ? _buildEmptyState(context, trip, day)
              : Theme(
                  data: ThemeData(
                    canvasColor: Colors.transparent, 
                  ),
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: day.activities.length,
                    onReorder: (oldIndex, newIndex) {
                      context.read<TripProvider>().reorderActivities(trip.id, day.dayIndex, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final activity = day.activities[index];
                      return _buildActivityItem(
                        context, 
                        trip, 
                        day, 
                        activity, 
                        index, 
                        arrivalTimes.length > index ? arrivalTimes[index] : '??:??',
                        key: ValueKey(activity.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<String> _calculateArrivalTimes(TripDay day) {
    List<String> times = [];
    if (day.activities.isEmpty) return [];

    try {
      DateTime currentTime = DateFormat('HH:mm').parse(day.startTime);
      
      for (int i = 0; i < day.activities.length; i++) {
        final activity = day.activities[i];
        
        if (i > 0 && activity.travelDurationFromPrevious != null) {
          currentTime = currentTime.add(Duration(minutes: activity.travelDurationFromPrevious!));
        }
        
        times.add(DateFormat('HH:mm').format(currentTime));
        currentTime = currentTime.add(Duration(minutes: activity.duration));
      }
    } catch (e) {
      return List.generate(day.activities.length, (index) => '??:??');
    }
    
    return times;
  }

  Future<void> _selectStartTime(BuildContext context, Trip trip, TripDay day) async {
    final parts = day.startTime.split(':');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );
    if (picked != null) {
      final String formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (context.mounted) {
        context.read<TripProvider>().updateDayStartTime(trip.id, day.dayIndex, formattedTime);
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

  Widget _buildActivityItem(
    BuildContext context, 
    Trip trip, 
    TripDay day, 
    Activity activity, 
    int index, 
    String arrivalTime,
    {required Key key}
  ) {
    return Column(
      key: key,
      children: [
        // Item 2: Transport picker MOVED to timeline
        if (index > 0) _buildTimelineTransportDivider(context, trip, day, activity),
        Dismissible(
          key: Key('dismiss_${activity.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<TripProvider>().deleteActivity(trip.id, day.dayIndex, activity.id);
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
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(_getCategoryIcon(activity), color: _getCategoryIconColor(activity), size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(activity.duration),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        arrivalTime,
                                        style: const TextStyle(color: TripiColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activity.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                      ),
                                      if (activity.address != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            activity.address!,
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'View Details →',
                                        style: TextStyle(color: TripiColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.drag_indicator, color: Color(0xFFCBD5E1), size: 24),
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

  // Item 1: Helper for Category Icon
  IconData _getCategoryIcon(Activity activity) {
    if (activity.types == null) return Icons.place;
    if (activity.types!.contains('lodging')) return Icons.hotel;
    if (activity.types!.contains('restaurant') || activity.types!.contains('food') || activity.types!.contains('cafe')) return Icons.restaurant;
    if (activity.types!.contains('airport') || activity.types!.contains('transit_station')) return Icons.flight;
    if (activity.types!.contains('museum') || activity.types!.contains('tourist_attraction')) return Icons.local_see;
    if (activity.types!.contains('park')) return Icons.park;
    return Icons.place;
  }

  // Item 1: Helper for Category Color
  Color _getCategoryColor(Activity activity) {
    if (activity.types == null) return Colors.white;
    if (activity.types!.contains('lodging')) return Colors.white; // White circle, blue icon
    if (activity.types!.contains('restaurant') || activity.types!.contains('food')) return const Color(0xFFDDD6FE); // Purple
    if (activity.types!.contains('airport')) return const Color(0xFF0284C7); // Blue
    return Colors.white;
  }

  Color _getCategoryIconColor(Activity activity) {
    if (activity.types == null) return const Color(0xFF64748B);
    if (activity.types!.contains('lodging')) return const Color(0xFF0284C7);
    if (activity.types!.contains('airport')) return Colors.white;
    if (activity.types!.contains('restaurant') || activity.types!.contains('food')) return const Color(0xFF7C3AED);
    return const Color(0xFF64748B);
  }

  // Item 2: Transport Picker on Timeline Line
  Widget _buildTimelineTransportDivider(BuildContext context, Trip trip, TripDay day, Activity activity) {
    final mode = activity.transportModeFromPrevious ?? TravelMode.driving;
    final duration = activity.travelDurationFromPrevious ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Center(
            child: Container(width: 2, height: 40, color: const Color(0xFFE2E8F0)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showTransportPicker(context, trip, day, activity),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getTransportIcon(mode), size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  duration > 0 ? _formatDuration(duration) : 'Calculating...',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTransportIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking: return Icons.directions_walk;
      case TravelMode.driving: return Icons.directions_car;
      case TravelMode.transit: return Icons.directions_bus;
      case TravelMode.flight: return Icons.flight;
    }
  }

  void _showTransportPicker(BuildContext context, Trip trip, TripDay day, Activity activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transport Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: TravelMode.values.map((mode) {
                return GestureDetector(
                  onTap: () {
                    context.read<TripProvider>().updateActivityTransportAuto(
                      trip.id, 
                      day.dayIndex, 
                      activity.id, 
                      mode,
                    );
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activity.transportModeFromPrevious == mode ? TripiColors.primary.withOpacity(0.1) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTransportIcon(mode), 
                          color: activity.transportModeFromPrevious == mode ? TripiColors.primary : const Color(0xFF64748B)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(mode.name, style: TextStyle(fontSize: 12, color: activity.transportModeFromPrevious == mode ? TripiColors.primary : const Color(0xFF64748B))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Trip trip, TripDay day) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, size: 64, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No activities planned yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start adding places you want to visit!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddActivity(BuildContext context, Trip trip, TripDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(tripId: trip.id, dayIndex: day.dayIndex),
      ),
    );
  }
}
