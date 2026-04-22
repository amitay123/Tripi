enum TripType { leisure, business, family, friends, solo, romantic }
enum TravelStyle { standard, luxury, budget, backpacker }
enum TripPace { relaxed, balanced, intensive }
enum TravelMode { walking, driving, transit, flight }

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

class Activity {
  final String id;
  final String title;
  final double? lat;
  final double? lng;
  final String? address;
  final String? startTime; // "HH:mm"
  final String? endTime;   // "HH:mm"
  final String? notes;
  final String? imageUrl;
  final String source; // 'manual' or 'api'
  final String? placeId;
  final List<String>? types;
  final int duration; // in minutes
  final TravelMode? transportModeFromPrevious;
  final int? travelDurationFromPrevious; // in minutes

  Activity({
    required this.id,
    required this.title,
    this.lat,
    this.lng,
    this.address,
    this.startTime,
    this.endTime,
    this.notes,
    this.imageUrl,
    this.source = 'manual',
    this.placeId,
    this.types,
    this.duration = 60,
    this.transportModeFromPrevious,
    this.travelDurationFromPrevious,
  });

  Activity copyWith({
    String? id,
    String? title,
    double? lat,
    double? lng,
    String? address,
    String? startTime,
    String? endTime,
    String? notes,
    String? imageUrl,
    String? source,
    String? placeId,
    List<String>? types,
    int? duration,
    TravelMode? transportModeFromPrevious,
    int? travelDurationFromPrevious,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      placeId: placeId ?? this.placeId,
      types: types ?? this.types,
      duration: duration ?? this.duration,
      transportModeFromPrevious: transportModeFromPrevious ?? this.transportModeFromPrevious,
      travelDurationFromPrevious: travelDurationFromPrevious ?? this.travelDurationFromPrevious,
    );
  }
}

class TripDay {
  final int dayIndex;
  final DateTime date;
  final List<Activity> activities;
  final String startTime; // "HH:mm"

  TripDay({
    required this.dayIndex,
    required this.date,
    this.activities = const [],
    this.startTime = "09:00",
  });

  TripDay copyWith({
    int? dayIndex,
    DateTime? date,
    List<Activity>? activities,
    String? startTime,
  }) {
    return TripDay(
      dayIndex: dayIndex ?? this.dayIndex,
      date: date ?? this.date,
      activities: activities ?? this.activities,
      startTime: startTime ?? this.startTime,
    );
  }
}

class Trip {
  final String id;
  final String userId;
  final String name;
  final String country;
  final String? countryCode; // ISO2/3
  final String? city;
  final String? cityPlaceId;
  final DateTime startDate;
  final DateTime endDate;
  final int travelersCount;
  final Map<String, int> travelersBreakdown;
  final TripType tripType;
  final TravelStyle travelStyle;
  final double? budgetTotal;
  final String currency;
  final List<String> preferences;
  final TripPace pace;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TripDay> days; // Changed from List<String> activities
  final String? coverImageUrl;
  final Destination? destination;

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.country,
    this.countryCode,
    this.city,
    this.cityPlaceId,
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
    this.days = const [],
    this.coverImageUrl,
    this.destination,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;
  double? get budgetDaily => (budgetTotal != null && durationDays > 0) ? budgetTotal! / durationDays : null;

  Trip copyWith({
    String? id,
    String? name,
    String? country,
    String? countryCode,
    String? city,
    String? cityPlaceId,
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
    List<TripDay>? days,
    String? coverImageUrl,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      cityPlaceId: cityPlaceId ?? this.cityPlaceId,
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
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      destination: destination,
    );
  }
}
