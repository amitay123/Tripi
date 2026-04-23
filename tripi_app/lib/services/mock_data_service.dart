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
    ActivityLog(
        userName: 'Sarah Chen',
        action: 'created a new trip to Kyoto',
        timeAgo: '12 minutes ago'),
    ActivityLog(
        userName: 'Marcus Wright',
        action: 'updated travel preferences',
        timeAgo: '45 minutes ago'),
    ActivityLog(
        userName: 'Amitay Gilad',
        action: 'approved 4 enterprise bookings',
        timeAgo: '2 hours ago'),
    ActivityLog(
        userName: 'Elena Rodriguez',
        action: 'requested support for flight #AX90',
        timeAgo: '5 hours ago'),
  ];

  static final List<Destination> destinations = [
    Destination(
      id: '1',
      name: 'Paris',
      country: 'France',
      imageUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800',
      description:
          'The City of Light, where history meets high-fashion and editorial elegance.',
      rating: 4.8,
    ),
    Destination(
      id: '2',
      name: 'Maldives',
      country: 'Maldives',
      imageUrl:
          'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?q=80&w=800',
      description:
          'A serene escape into the turquoise blue, perfect for the minimalist soul.',
      rating: 4.9,
    ),
    Destination(
      id: '3',
      name: 'Tokyo',
      country: 'Japan',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800',
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
      name: 'Paris Getaway',
      country: 'France',
      city: 'Paris',
      destination: destinations[0],
      startDate: DateTime.now().add(const Duration(days: 12)),
      endDate: DateTime.now().add(const Duration(days: 17)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      days: [
        TripDay(
          dayIndex: 1,
          date: DateTime.now().add(const Duration(days: 12)),
          activities: [
            Activity(
              id: 'a1',
              title: 'Coffee at Café de Flore',
              startTime: '09:00',
              address: '172 Bd Saint-Germain, 75006 Paris',
              imageUrl:
                  'https://images.unsplash.com/photo-1550983092-247321459255?q=80&w=400',
            ),
            Activity(
              id: 'a2',
              title: 'Louvre Museum',
              startTime: '11:00',
              address: 'Rue de Rivoli, 75001 Paris',
              imageUrl:
                  'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=400',
            ),
          ],
        ),
        TripDay(
          dayIndex: 2,
          date: DateTime.now().add(const Duration(days: 13)),
          activities: [
            Activity(
              id: 'a3',
              title: 'Eiffel Tower Visit',
              startTime: '10:00',
              address: 'Champ de Mars, 5 Av. Anatole France, 75007 Paris',
              imageUrl:
                  'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?q=80&w=400',
            ),
          ],
        ),
      ],
    ),
  ];

  static final List<String> popularCountries = [
    'France',
    'Italy',
    'United States',
    'Japan',
    'Thailand',
    'Greece',
    'Switzerland',
    'Spain',
    'Israel'
  ];

  static String getDestinationImage(String? city, String country) {
    // Priority 1: City + Country travel image
    // Priority 2: Country travel image
    // Using loremflickr which is very reliable for tag-based images
    final String cleanCountry = country.replaceAll(' ', '');
    final String? cleanCity = city?.replaceAll(' ', '');

    if (cleanCity != null && cleanCity.isNotEmpty) {
      return 'https://loremflickr.com/800/600/$cleanCity,$cleanCountry,travel/all';
    }
    return 'https://loremflickr.com/800/600/$cleanCountry,travel/all';
  }

  static List<Trip> getTripsForUser(String userId) {
    return allTrips.where((trip) => trip.userId == userId).toList();
  }
}
