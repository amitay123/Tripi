import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../models/models.dart';

import '../providers/trip_provider.dart';
import 'create_trip/create_trip_wizard.dart';
import 'itinerary_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _isLoading = true;

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

  void _editTripField(BuildContext context, Trip trip, int targetStep) {
    Navigator.pop(context); // Close modal first
    
    // Use microtask to ensure state updates and navigation happen after modal dismissal
    Future.microtask(() {
      if (!context.mounted) return;
      
      final tripProvider = context.read<TripProvider>();
      tripProvider.resumeTrip(trip);
      tripProvider.goToStep(targetStep);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateTripWizard(),
        ),
      );
    });
  }

  void _showTripInfo(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                        trip.name,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.city ?? ''}, ${trip.country}'.replaceAll(RegExp(r'^,\s*'), ''),
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 16),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editTripField(context, trip, 0),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
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
                _buildInfoBadge(Icons.person,
                    '${trip.travelersBreakdown['adults'] ?? 1} Adults',
                    () => _editTripField(context, trip, 1)),
                const SizedBox(width: 12),
                _buildInfoBadge(Icons.child_care,
                    '${trip.travelersBreakdown['children'] ?? 0} Children',
                    () => _editTripField(context, trip, 1)),
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
                _buildInfoTag(Icons.category,
                    'Type: ${trip.tripType.name[0].toUpperCase()}${trip.tripType.name.substring(1)}',
                    () => _editTripField(context, trip, 2)),
                _buildInfoTag(Icons.speed,
                    'Pace: ${trip.pace.name[0].toUpperCase()}${trip.pace.name.substring(1)}',
                    () => _editTripField(context, trip, 2)),
                if (trip.preferences.isNotEmpty)
                  ...trip.preferences.map((p) => _buildInfoTag(Icons.star, p,
                      () => _editTripField(context, trip, 2))),
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
          'Serene Navigator',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                  'https://images.weserv.nl/?url=${Uri.encodeComponent('https://i.pravatar.cc/150?u=admin_user')}'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? EmptyTripsView(onPlanTrip: () => _startWizard(context))
              : _buildTripsList(context, trips),
    );
  }

  Widget _buildTripsList(BuildContext context, List<dynamic> trips) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your Trips',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
          ),
          const SizedBox(height: 24),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search trips, destinations...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
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
                        color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Featured Trip Card (First Trip)
          if (trips.isNotEmpty) _buildFeaturedTrip(context, trips[0]),
          const SizedBox(height: 16),
          // Plan New Trip Card (Now second)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPlanNewTripCard(context),
          ),
          // Other Trips List
          ...trips.skip(1).map((trip) => _buildTripListItem(context, trip)),
          const SizedBox(height: 24),
        ],
      ),
    );
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
                  trip.coverImageUrl ??
                      trip.destination?.imageUrl ??
                      'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800',
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
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'IN 12 DAYS',
                    style: TextStyle(
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
                        onTap: () => _showTripInfo(context, trip),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                        onTap: () =>
                            _showDeleteConfirmation(context, trip.id, trip.name),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                const Row(
                  children: [
                    Icon(Icons.airplanemode_active,
                        size: 18, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text('CDG • Air France',
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
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
                trip.coverImageUrl ??
                    trip.destination?.imageUrl ??
                    'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800',
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
                  const Text('Planning stage',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline,
                  color: Color(0xFF2563EB), size: 24),
              onPressed: () => _showTripInfo(context, trip),
            ),
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Colors.redAccent, size: 24),
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
                          color: Colors.black.withOpacity(0.03),
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
                          color: Colors.black.withOpacity(0.02),
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
                            color: Colors.black.withOpacity(0.05),
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
                            color: Colors.black.withOpacity(0.05),
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
