import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../models/models.dart';
import '../providers/booking_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/modals/trip_edit_modals.dart';
import 'create_trip/create_trip_wizard.dart';
import 'itinerary_screen.dart';
import '../services/mock_data_service.dart';
import '../widgets/ai/ai_planning_options_sheet.dart';
import 'ai_review_screen.dart';
import '../providers/ai_provider.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    await context.read<TripProvider>().fetchTrips();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startWizard(BuildContext context) {
    context.read<TripProvider>().startNewTrip();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripWizard()),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String tripId, String tripName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Trip',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "$tripName"? it will be removed from your view but kept in our records for 1 year.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TripProvider>().deleteTrip(tripId);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trip "$tripName" deleted.'),
                  action: SnackBarAction(
                    label: 'DISMISS',
                    onPressed: () {},
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _editTripField(BuildContext context, Trip trip, int fieldIndex) {
    if (fieldIndex == 0) {
      EditDetailsModal.show(context, trip);
    } else if (fieldIndex == 1) {
      EditTravelersModal.show(context, trip);
    } else if (fieldIndex == 2) {
      EditPreferencesModal.show(context, trip);
    }
  }

  void _showTripInfo(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<TripProvider>(
        builder: (context, provider, _) {
          final latestTrip = provider.trips.firstWhere(
            (t) => t.id == trip.id,
            orElse: () => trip,
          );

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestTrip.name,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latestTrip.city ?? ''}, ${latestTrip.country}'
                                .replaceAll(RegExp(r'^,\s*'), ''),
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editTripField(context, latestTrip, 0),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Color(0xFF2563EB), size: 20),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                const Text(
                  'TRAVELERS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoBadge(
                        Icons.person,
                        '${latestTrip.travelersBreakdown['adults'] ?? 1} Adults',
                        () => _editTripField(context, latestTrip, 1)),
                    const SizedBox(width: 12),
                    _buildInfoBadge(
                        Icons.child_care,
                        '${latestTrip.travelersBreakdown['children'] ?? 0} Children',
                        () => _editTripField(context, latestTrip, 1)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'TRIP STYLE & PREFERENCES',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoTag(
                        Icons.category,
                        'Type: ${latestTrip.tripType.name[0].toUpperCase()}${latestTrip.tripType.name.substring(1)}',
                        () => _editTripField(context, latestTrip, 2)),
                    _buildInfoTag(
                        Icons.speed,
                        'Pace: ${latestTrip.pace.name[0].toUpperCase()}${latestTrip.pace.name.substring(1)}',
                        () => _editTripField(context, latestTrip, 2)),
                    if (latestTrip.preferences.isNotEmpty)
                      ...latestTrip.preferences.map((p) => _buildInfoTag(
                          Icons.star,
                          p,
                          () => _editTripField(context, latestTrip, 2))),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF4B5563),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAiOptions(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiPlanningOptionsSheet(
        onGenerate: (options) {
          // Default to Day 1 when starting from main screen
          const dayIndex = 1;

          // Reset provider to clear any stale state before generation
          context.read<AiProvider>().reset();

          // Kick off generation
          context.read<AiProvider>().generateDailyItinerary(
                trip: trip,
                dayIndex: dayIndex,
                options: options,
              );

          // Navigate to review screen (it will observe the loading state)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiReviewScreen(trip: trip, dayIndex: dayIndex),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>().trips;

    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: TripiColors.primary),
        centerTitle: true,
        title: Text(
          'Tripi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, _) {
                final user = bookingProvider.currentUser;
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.profileImage != null
                      ? NetworkImage(user!.profileImage!)
                      : const NetworkImage(
                          'https://i.pravatar.cc/150?u=tripi_guest'),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? EmptyTripsView(onPlanTrip: () => _startWizard(context))
              : _buildTripsBody(context, trips),
    );
  }

  Widget _buildDropdownItem(BuildContext context, dynamic trip) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(
              MockDataService.getDestinationImage(trip.city, trip.country),
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        trip.name,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
      ),
      subtitle: Text(
        trip.city != null ? '${trip.city}, ${trip.country}' : trip.country,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      ),
      onTap: () {
        _searchController.clear();
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        if (!trip.isCompleted) {
          context.read<TripProvider>().resumeTrip(trip);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripWizard()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ItineraryScreen(tripId: trip.id)),
          );
        }
      },
    );
  }

  Widget _buildTripsBody(BuildContext context, List<dynamic> trips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed header: title + search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Trips',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _isSearching = value.isNotEmpty;
                    if (_isSearching) {
                      final query = value.toLowerCase();
                      _searchResults = trips.where((trip) {
                        final nameMatch =
                            trip.name.toLowerCase().contains(query);
                        final cityMatch =
                            trip.city?.toLowerCase().contains(query) ?? false;
                        final countryMatch =
                            trip.country.toLowerCase().contains(query);
                        return nameMatch || cityMatch || countryMatch;
                      }).toList();
                    } else {
                      _searchResults = [];
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search trips, destinations...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
        // Expandable area: trips list + floating dropdown
        Expanded(
          child: Stack(
            children: [
              _buildTripsList(context, trips),
              // Floating dropdown - appears right below search bar
              if (_isSearching)
                Positioned(
                  top: 8,
                  left: 24,
                  right: 24,
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    child: _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.search_off,
                                    color: Color(0xFF9CA3AF)),
                                SizedBox(width: 12),
                                Text(
                                  'No trips found',
                                  style: TextStyle(
                                      color: Color(0xFF6B7280), fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) =>
                                    _buildDropdownItem(
                                        context, _searchResults[index]),
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsList(BuildContext context, List<dynamic> trips) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter and sort upcoming trips (soonest first)
    final upcomingTrips = trips.where((t) {
      final end = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return !end.isBefore(today);
    }).toList();
    upcomingTrips.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Filter and sort past trips (most recent first)
    final pastTrips = trips.where((t) {
      final end = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return end.isBefore(today);
    }).toList();
    pastTrips.sort((a, b) => b.startDate.compareTo(a.startDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SizedBox(height: 32),

          if (upcomingTrips.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All',
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 1. Topmost trip (Soonest)
            _buildFeaturedTrip(context, upcomingTrips[0]),
            const SizedBox(height: 16),
          ],

          // 2. Plan New Trip Card (Always second)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildPlanNewTripCard(context),
          ),

          // 3. Rest of the upcoming trips
          if (upcomingTrips.length > 1) ...[
            ...upcomingTrips
                .skip(1)
                .map((trip) => _buildTripListItem(context, trip)),
            const SizedBox(height: 24),
          ],

          if (pastTrips.isNotEmpty) ...[
            const Text(
              'טיולים שחלפו',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            ...pastTrips.map((trip) => _buildTripListItem(context, trip)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  String? _getCountdownText(DateTime startDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    if (start.isAtSameMomentAs(today)) {
      return 'today';
    }

    if (start.isAfter(today)) {
      final difference = start.difference(today).inDays;
      return 'IN $difference DAYS';
    }

    return null;
  }

  Widget _buildFeaturedTrip(BuildContext context, dynamic trip) {
    return TripiCard(
      onTap: () {
        if (!trip.isCompleted) {
          context.read<TripProvider>().resumeTrip(trip);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripWizard()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ItineraryScreen(tripId: trip.id)),
          );
        }
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                child: Image.network(
                  MockDataService.getDestinationImage(trip.city, trip.country),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Image unavailable',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_getCountdownText(trip.startDate) != null)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCountdownText(trip.startDate)!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              Positioned(
                top: 20,
                right: 20,
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAiOptions(context, trip),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: TripiColors.primary.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showTripInfo(context, trip),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDeleteConfirmation(
                            context, trip.id, trip.name),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('MMM dd').format(trip.startDate).toUpperCase()} - ${DateFormat('MMM dd').format(trip.endDate).toUpperCase()}',
                  style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  trip.name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                        trip.city != null
                            ? '${trip.city}, ${trip.country}'
                            : trip.country,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripListItem(BuildContext context, dynamic trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TripiCard(
        onTap: () {
          if (!trip.isCompleted) {
            context.read<TripProvider>().resumeTrip(trip);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTripWizard()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ItineraryScreen(tripId: trip.id)),
            );
          }
        },
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                MockDataService.getDestinationImage(trip.city, trip.country),
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.landscape, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('MMM dd').format(trip.startDate).toUpperCase()} - ${DateFormat('MMM dd').format(trip.endDate).toUpperCase()}',
                    style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      trip.city != null
                          ? '${trip.city}, ${trip.country}'
                          : trip.country,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12)),
                  if (_getCountdownText(trip.startDate) != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getCountdownText(trip.startDate)!,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome,
                  color: TripiColors.primary, size: 24),
              onPressed: () => _showAiOptions(context, trip),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline,
                  color: Color(0xFF2563EB), size: 24),
              onPressed: () => _showTripInfo(context, trip),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
              onPressed: () =>
                  _showDeleteConfirmation(context, trip.id, trip.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanNewTripCard(BuildContext context) {
    return TripiCard(
      onTap: () => _startWizard(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 30),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan New Trip',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E40AF)),
              ),
              SizedBox(height: 4),
              Text('Start your next adventure',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyTripsView extends StatelessWidget {
  final VoidCallback onPlanTrip;
  const EmptyTripsView({super.key, required this.onPlanTrip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Illustration Stack
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 40,
                          spreadRadius: 10),
                    ],
                  ),
                ),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore,
                          color: Color(0xFF2563EB), size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.airplanemode_active,
                        color: Color(0xFF6B7280), size: 24),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 40,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.map,
                        color: Color(0xFF2563EB), size: 24),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'No adventures yet?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          const Text(
            'The world is waiting for you. Start planning your next journey and let\'s make some memories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: onPlanTrip,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Plan a New Trip'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: const Color(0xFF0056B3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text(
              'BROWSE POPULAR DESTINATIONS',
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
