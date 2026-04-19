import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/tripi_card.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<BookingProvider>().userTrips;

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin_user'),
            ),
          ),
        ],
      ),
      body: trips.isEmpty ? const EmptyTripsView() : _buildTripsList(context, trips),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Featured Trip Card (First Trip)
          if (trips.isNotEmpty) _buildFeaturedTrip(context, trips[0]),
          const SizedBox(height: 24),
          // Other Trips List
          ...trips.skip(1).map((trip) => _buildTripListItem(context, trip)),
          const SizedBox(height: 24),
          // Plan New Trip Button at the bottom
          _buildPlanNewTripCard(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeaturedTrip(BuildContext context, dynamic trip) {
    return TripiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  image: DecorationImage(
                    image: NetworkImage(trip.destination.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'IN 12 DAYS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
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
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  trip.destination.name + ' Getaway',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.airplanemode_active, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    const Text('CDG • Air France', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(trip.destination.imageUrl),
                  fit: BoxFit.cover,
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
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destination.name + ' Autumn',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Planning stage', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanNewTripCard(BuildContext context) {
    return TripiCard(
      onTap: () => context.read<BookingProvider>().addMockTrip(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan New Trip',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E40AF)),
              ),
              const SizedBox(height: 4),
              const Text('Start your next adventure', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyTripsView extends StatelessWidget {
  const EmptyTripsView({super.key});

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
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, spreadRadius: 10),
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
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore, color: Color(0xFF2563EB), size: 40),
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
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.airplanemode_active, color: Color(0xFF6B7280), size: 24),
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
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.map, color: Color(0xFF2563EB), size: 24),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'No adventures yet?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          const Text(
            'The world is waiting for you. Start planning your next journey and let\'s make some memories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => context.read<BookingProvider>().addMockTrip(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Plan a New Trip'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: const Color(0xFF0056B3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text(
              'BROWSE POPULAR DESTINATIONS',
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
