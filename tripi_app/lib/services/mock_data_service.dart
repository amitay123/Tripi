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
    User(id: 'u1', email: 'traveler@example.com', name: 'Amitay'),
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

  static const Map<String, String> _destinationPhotos = {
    // ── CITIES ──────────────────────────────────────────────────────────────
    'paris':         'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',
    'london':        'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',
    'new york':      'https://images.unsplash.com/photo-1546436836-07a91091f160?w=800&q=80',
    'new york city': 'https://images.unsplash.com/photo-1546436836-07a91091f160?w=800&q=80',
    'nyc':           'https://images.unsplash.com/photo-1546436836-07a91091f160?w=800&q=80',
    'tokyo':         'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
    'dubai':         'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',
    'rome':          'https://images.unsplash.com/photo-1525874684015-58379d421a52?w=800&q=80',
    'barcelona':     'https://images.unsplash.com/photo-1523531294919-4bcd7c65e216?w=800&q=80',
    'amsterdam':     'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=800&q=80',
    'singapore':     'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
    'sydney':        'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',
    'cairo':         'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800&q=80',
    'istanbul':      'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800&q=80',
    'bangkok':       'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=800&q=80',
    'bali':          'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80',
    'kyoto':         'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',
    'santorini':     'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
    'prague':        'https://images.unsplash.com/photo-1541849546-216549ae216d?w=800&q=80',
    'venice':        'https://images.unsplash.com/photo-1514890547357-a9ee288728e0?w=800&q=80',
    'marrakech':     'https://images.unsplash.com/photo-1553177595-4de2d013a47b?w=800&q=80',
    'miami':         'https://images.unsplash.com/photo-1514214246283-d427a95c5d2f?w=800&q=80',
    'los angeles':   'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
    'las vegas':     'https://images.unsplash.com/photo-1605833556294-ea5c7a74f57d?w=800&q=80',
    'berlin':        'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',
    'vienna':        'https://images.unsplash.com/photo-1516550893923-42d28e5677af?w=800&q=80',
    'madrid':        'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',
    'lisbon':        'https://images.unsplash.com/photo-1558370781-d6196949e317?w=800&q=80',
    'seoul':         'https://images.unsplash.com/photo-1538485399081-7191377e8241?w=800&q=80',
    'mumbai':        'https://images.unsplash.com/photo-1529253355930-ddbe423a2ac7?w=800&q=80',
    'delhi':         'https://images.unsplash.com/photo-1597040663342-45b6af3d91a5?w=800&q=80',
    'new delhi':     'https://images.unsplash.com/photo-1597040663342-45b6af3d91a5?w=800&q=80',
    'kerala':        'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800&q=80',
    'kuwait city':   'https://images.unsplash.com/photo-1621243804936-775306a8f2e3?w=800&q=80',
    'marina mall':   'https://images.unsplash.com/photo-1621243804936-775306a8f2e3?w=800&q=80',
    'tel aviv':      'https://images.unsplash.com/photo-1544013938-5a56e7766c81?w=800&q=80',
    'jerusalem':     'https://images.unsplash.com/photo-1552423314-cf29ab68ad73?w=800&q=80',
    'hong kong':     'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?w=800&q=80',
    'shanghai':      'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800&q=80',
    'beijing':       'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
    'moscow':        'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=800&q=80',
    'rio de janeiro':'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',
    'buenos aires':  'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',
    'cape town':     'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',
    'nairobi':       'https://images.unsplash.com/photo-1611348586804-61bf6c080437?w=800&q=80',
    'zurich':        'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',
    'brussels':      'https://images.unsplash.com/photo-1559113202-c916b8e44373?w=800&q=80',
    'florence':      'https://images.unsplash.com/photo-1541370976299-4d24be63769a?w=800&q=80',
    'milan':         'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=800&q=80',
    'athens':        'https://images.unsplash.com/photo-1555993539-1732b0258235?w=800&q=80',
    'maldives':      'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800&q=80',
    'phuket':        'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?w=800&q=80',
    'chiang mai':    'https://images.unsplash.com/photo-1523731407965-2430cd12f5e4?w=800&q=80',
    'dubai marina':  'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',
    'abu dhabi':     'https://images.unsplash.com/photo-1544948503-7ad532728898?w=800&q=80',
    'doha':          'https://images.unsplash.com/photo-1577017040065-650ee4d43339?w=800&q=80',
    'muscat':        'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=800&q=80',
    'amman':         'https://images.unsplash.com/photo-1580834341580-8c17a3a630ca?w=800&q=80',
    'beirut':        'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',
    'toronto':       'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800&q=80',
    'vancouver':     'https://images.unsplash.com/photo-1559511260-0bafa6fc8b4c?w=800&q=80',
    'chicago':       'https://images.unsplash.com/photo-1494522855154-9297ac14b55f?w=800&q=80',
    'san francisco': 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&q=80',
    'mexico city':   'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',
    'cancun':        'https://images.unsplash.com/photo-1552074284-5e88ef1aef18?w=800&q=80',
    // ── COUNTRIES ────────────────────────────────────────────────────────────
    'france':               'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',
    'uk':                   'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',
    'united kingdom':       'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',
    'england':              'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',
    'usa':                  'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
    'united states':        'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
    'japan':                'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
    'italy':                'https://images.unsplash.com/photo-1525874684015-58379d421a52?w=800&q=80',
    'spain':                'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',
    'greece':               'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
    'australia':            'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',
    'india':                'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800&q=80',
    'egypt':                'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800&q=80',
    'turkey':               'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800&q=80',
    'indonesia':            'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80',
    'thailand':             'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=800&q=80',
    'morocco':              'https://images.unsplash.com/photo-1553177595-4de2d013a47b?w=800&q=80',
    'uae':                  'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',
    'united arab emirates': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',
    'netherlands':          'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=800&q=80',
    'portugal':             'https://images.unsplash.com/photo-1558370781-d6196949e317?w=800&q=80',
    'germany':              'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',
    'austria':              'https://images.unsplash.com/photo-1516550893923-42d28e5677af?w=800&q=80',
    'south korea':          'https://images.unsplash.com/photo-1538485399081-7191377e8241?w=800&q=80',
    'china':                'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
    'russia':               'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=800&q=80',
    'brazil':               'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',
    'argentina':            'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',
    'south africa':         'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',
    'kenya':                'https://images.unsplash.com/photo-1611348586804-61bf6c080437?w=800&q=80',
    'switzerland':          'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',
    'belgium':              'https://images.unsplash.com/photo-1559113202-c916b8e44373?w=800&q=80',
    'israel':               'https://images.unsplash.com/photo-1552423314-cf29ab68ad73?w=800&q=80',
    'kuwait':               'https://images.unsplash.com/photo-1621243804936-775306a8f2e3?w=800&q=80',
    'qatar':                'https://images.unsplash.com/photo-1577017040065-650ee4d43339?w=800&q=80',
    'oman':                 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=800&q=80',
    'jordan':               'https://images.unsplash.com/photo-1580834341580-8c17a3a630ca?w=800&q=80',
    'lebanon':              'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',
    'canada':               'https://images.unsplash.com/photo-1559511260-0bafa6fc8b4c?w=800&q=80',
    'mexico':               'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',
    'maldives':             'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800&q=80',
    'czech republic':       'https://images.unsplash.com/photo-1541849546-216549ae216d?w=800&q=80',
    'czechia':              'https://images.unsplash.com/photo-1541849546-216549ae216d?w=800&q=80',
  };

  static String getDestinationImage(String? city, String country) {
    final cityKey = city?.trim().toLowerCase() ?? '';
    final countryKey = country.trim().toLowerCase();

    // 1. Try exact city match
    if (cityKey.isNotEmpty && _destinationPhotos.containsKey(cityKey)) {
      return _destinationPhotos[cityKey]!;
    }
    // 2. Try exact country match
    if (_destinationPhotos.containsKey(countryKey)) {
      return _destinationPhotos[countryKey]!;
    }
    // 3. Partial match – check if any key is contained in the destination
    final query = cityKey.isNotEmpty ? cityKey : countryKey;
    for (final key in _destinationPhotos.keys) {
      if (query.contains(key) || key.contains(query)) {
        return _destinationPhotos[key]!;
      }
    }
    // 4. Fallback: loremflickr with large seed to minimise collisions
    final int seed = query.hashCode.abs() % 100000;
    return 'https://loremflickr.com/800/600/$query?lock=$seed';
  }

  static List<Trip> getTripsForUser(String userId) {
    return allTrips.where((trip) => trip.userId == userId).toList();
  }
}
