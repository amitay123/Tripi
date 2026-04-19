import '../models/models.dart';

class AdminStats {
  final int totalTrips;
  final int activeTrips;
  final double monthlyGrowth;
  final Map<String, double> topDestinations; // Region: Percentage
  final List<int> usageStats; // Last 10 intervals

  AdminStats({
    required this.totalTrips,
    required this.activeTrips,
    required this.monthlyGrowth,
    required this.topDestinations,
    required this.usageStats,
  });
}

class ActivityLog {
  final String userName;
  final String action;
  final String timeAgo;
  final String? profileImageUrl;

  ActivityLog({
    required this.userName,
    required this.action,
    required this.timeAgo,
    this.profileImageUrl,
  });
}

class MockDataService {
  static final List<User> users = [
    User(id: 'u1', email: 'traveler@voyage.com', name: 'Amitay'),
    User(id: 'u2', email: 'user2@tripi.com', name: 'John Doe'),
    User(id: 'u3', email: 'alex@example.com', name: 'Alex Johnson'),
    User(id: 'u4', email: 'marcus.c@example.com', name: 'Marcus Chen'),
  ];

  static final AdminStats adminStats = AdminStats(
    totalTrips: 45802,
    activeTrips: 1204,
    monthlyGrowth: 18.2,
    topDestinations: {'Europe': 45.0, 'Asia': 27.0, 'Others': 28.0},
    usageStats: [5, 8, 7, 10, 15, 12, 11, 13, 9, 7],
  );

  static final List<ActivityLog> recentActivity = [
    ActivityLog(userName: 'Sarah Chen', action: 'created a new trip to Kyoto', timeAgo: '12 minutes ago'),
    ActivityLog(userName: 'Marcus Wright', action: 'updated travel preferences', timeAgo: '45 minutes ago'),
    ActivityLog(userName: 'Amitay Gilad', action: 'approved 4 enterprise bookings', timeAgo: '2 hours ago'),
    ActivityLog(userName: 'Elena Rodriguez', action: 'requested support for flight #AX90', timeAgo: '5 hours ago'),
  ];

  static final List<Destination> destinations = [
    Destination(
      id: '1',
      name: 'Paris',
      country: 'France',
      imageUrl: 'assets/images/paris.png',
      description: 'The City of Light, where history meets high-fashion and editorial elegance.',
      rating: 4.8,
    ),
    Destination(
      id: '2',
      name: 'Maldives',
      country: 'Maldives',
      imageUrl: 'assets/images/maldives.png',
      description: 'A serene escape into the turquoise blue, perfect for the minimalist soul.',
      rating: 4.9,
    ),
    Destination(
      id: '3',
      name: 'Tokyo',
      country: 'Japan',
      imageUrl: 'assets/images/tokyo.png',
      description: 'A precise blend of tradition and future-forward design.',
      rating: 4.7,
    ),
  ];

  static final List<Flight> flights = [
    Flight(
      id: 'f1',
      airline: 'Air France',
      from: 'NYC',
      to: 'PAR',
      departure: DateTime.now().add(const Duration(days: 30, hours: 10)),
      arrival: DateTime.now().add(const Duration(days: 30, hours: 18)),
      price: 850.0,
    ),
  ];

  static final List<Trip> allTrips = [
    Trip(
      id: 't1',
      userId: 'u1',
      destination: destinations[0],
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 37)),
      activities: ['Eiffel Tower', 'Louvre Museum', 'Seine Cruise'],
    ),
  ];

  static List<Trip> getTripsForUser(String userId) {
    return allTrips.where((trip) => trip.userId == userId).toList();
  }
}
