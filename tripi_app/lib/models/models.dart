class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });
}

class Destination {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String description;
  final double rating;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.rating,
  });
}

class Flight {
  final String id;
  final String airline;
  final String from;
  final String to;
  final DateTime departure;
  final DateTime arrival;
  final double price;

  Flight({
    required this.id,
    required this.airline,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.price,
  });
}

enum TripType { leisure, business, family, friends, other }

enum TravelStyle { budget, standard, luxury }

enum TripPace { relaxed, balanced, intensive }

class Trip {
  final String id;
  final String userId;
  final String name;
  final String country;
  final String? city;
  final DateTime startDate;
  final DateTime endDate;
  final int travelersCount;
  final Map<String, int> travelersBreakdown; // e.g., {'adults': 2, 'children': 1}
  final TripType tripType;
  final TravelStyle travelStyle;
  final double? budgetTotal;
  final String currency;
  final List<String> preferences;
  final TripPace pace;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> activities;
  final Destination? destination; // Kept for backward compatibility if needed

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.country,
    this.city,
    required this.startDate,
    required this.endDate,
    this.travelersCount = 1,
    this.travelersBreakdown = const {'adults': 1},
    this.tripType = TripType.leisure,
    this.travelStyle = TravelStyle.standard,
    this.budgetTotal,
    this.currency = 'USD',
    this.preferences = const [],
    this.pace = TripPace.balanced,
    this.interests = const [],
    required this.createdAt,
    required this.updatedAt,
    this.activities = const [],
    this.destination,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;
  double? get budgetDaily => (budgetTotal != null && durationDays > 0) ? budgetTotal! / durationDays : null;

  Trip copyWith({
    String? name,
    String? country,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    int? travelersCount,
    Map<String, int>? travelersBreakdown,
    TripType? tripType,
    TravelStyle? travelStyle,
    double? budgetTotal,
    String? currency,
    List<String>? preferences,
    TripPace? pace,
    List<String>? interests,
    List<String>? activities,
  }) {
    return Trip(
      id: id,
      userId: userId,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelersCount: travelersCount ?? this.travelersCount,
      travelersBreakdown: travelersBreakdown ?? this.travelersBreakdown,
      tripType: tripType ?? this.tripType,
      travelStyle: travelStyle ?? this.travelStyle,
      budgetTotal: budgetTotal ?? this.budgetTotal,
      currency: currency ?? this.currency,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      interests: interests ?? this.interests,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      activities: activities ?? this.activities,
      destination: destination,
    );
  }
}
