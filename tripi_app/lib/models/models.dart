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
  final String? endTime; // "HH:mm"
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

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Activity',
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lng']?.toString() ?? ''),
      address: json['address']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      notes: json['notes']?.toString(),
      imageUrl: json['image_url']?.toString(),
      source: json['source']?.toString() ?? 'manual',
      placeId: json['place_id']?.toString(),
      types: (json['types'] as List?)?.map((e) => e.toString()).toList(),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 60,
      transportModeFromPrevious: TravelMode.values.firstWhere(
        (e) => e.name == (json['transport_mode_from_previous']?.toString() ?? 'driving'),
        orElse: () => TravelMode.driving,
      ),
      travelDurationFromPrevious: int.tryParse(json['travel_duration_from_previous']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lng': lng,
      'address': address,
      'start_time': startTime,
      'end_time': endTime,
      'notes': notes,
      'image_url': imageUrl,
      'source': source,
      'place_id': placeId,
      'types': types,
      'duration': duration,
      'transport_mode_from_previous': transportModeFromPrevious?.name,
      'travel_duration_from_previous': travelDurationFromPrevious,
    };
  }

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
      transportModeFromPrevious:
          transportModeFromPrevious ?? this.transportModeFromPrevious,
      travelDurationFromPrevious:
          travelDurationFromPrevious ?? this.travelDurationFromPrevious,
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

  factory TripDay.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    return TripDay(
      dayIndex: int.tryParse(json['day_index']?.toString() ?? '') ?? 1,
      date: parseDate(json['date']),
      activities: (json['activities'] as List?)
              ?.where((e) => e != null)
              .map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      startTime: json['start_time']?.toString() ?? "09:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_index': dayIndex,
      'date': date.toIso8601String(),
      'activities': activities.map((e) => e.toJson()).toList(),
      'start_time': startTime,
    };
  }

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
  final int currentStep;
  final bool isCompleted;
  final DateTime? deletedAt;

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
    this.currentStep = 0,
    this.isCompleted = false,
    this.deletedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    return Trip(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Trip',
      country: json['country']?.toString() ?? '',
      countryCode: json['country_code']?.toString(),
      city: json['city']?.toString(),
      cityPlaceId: json['city_place_id']?.toString(),
      startDate: parseDate(json['start_date']),
      endDate: parseDate(
          json['end_date'], DateTime.now().add(const Duration(days: 1))),
      travelersCount: int.tryParse(json['travelers_count']?.toString() ?? '') ?? 1,
      travelersBreakdown: Map<String, int>.from(json['travelers_breakdown'] ?? {}),
      tripType: TripType.values.firstWhere(
        (e) => e.name == (json['trip_type']?.toString() ?? 'leisure'),
        orElse: () => TripType.leisure,
      ),
      travelStyle: TravelStyle.values.firstWhere(
        (e) => e.name == (json['travel_style']?.toString() ?? 'standard'),
        orElse: () => TravelStyle.standard,
      ),
      budgetTotal: (json['budget_total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      preferences: List<String>.from(json['preferences'] ?? []),
      pace: TripPace.values.firstWhere(
        (e) => e.name == (json['pace']?.toString() ?? 'balanced'),
        orElse: () => TripPace.balanced,
      ),
      interests: List<String>.from(json['interests'] ?? []),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at'] ?? json['created_at']),
      days: (json['days'] as List?)
              ?.where((e) => e != null)
              .map((e) => TripDay.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      coverImageUrl: json['cover_image_url']?.toString(),
      currentStep: int.tryParse(json['current_step']?.toString() ?? '0') ?? 0,
      isCompleted: json['is_completed'] == true,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'country': country,
      'country_code': countryCode,
      'city': city,
      'city_place_id': cityPlaceId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'travelers_count': travelersCount,
      'travelers_breakdown': travelersBreakdown,
      'trip_type': tripType.name,
      'travel_style': travelStyle.name,
      'budget_total': budgetTotal,
      'currency': currency,
      'preferences': preferences,
      'pace': pace.name,
      'interests': interests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'days': days.map((e) => e.toJson()).toList(),
      'cover_image_url': coverImageUrl,
      'current_step': currentStep,
      'is_completed': isCompleted,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;
  double? get budgetDaily => (budgetTotal != null && durationDays > 0)
      ? budgetTotal! / durationDays
      : null;

  Trip copyWith({
    String? id,
    String? userId,
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
    int? currentStep,
    bool? isCompleted,
    DateTime? deletedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
