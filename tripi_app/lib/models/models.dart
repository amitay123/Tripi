class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final String? providerType;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.providerType,
  });
}

class Activity {
  final String time;
  final String title;
  final String description;
  final String? travelMode;
  final String? travelTime;

  Activity({
    required this.time,
    required this.title,
    required this.description,
    this.travelMode,
    this.travelTime,
  });
}

class DayItinerary {
  final int dayNumber;
  final List<Activity> activities;

  DayItinerary({
    required this.dayNumber,
    required this.activities,
  });
}

class Itinerary {
  final String title;
  final String location;
  final String imageUrl;
  final List<DayItinerary> days;

  Itinerary({
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.days,
  });
}

class PlaceDetail {
  final String name;
  final String? formattedAddress;
  final List<String> photoReferences;
  final double? rating;
  final Map<String, dynamic>? openingHours;
  final String? website;
  final int? priceLevel;
  final String? description;
  final List<String> types;

  PlaceDetail({
    required this.name,
    this.formattedAddress,
    this.photoReferences = const [],
    this.rating,
    this.openingHours,
    this.website,
    this.priceLevel,
    this.description,
    this.types = const [],
  });

  factory PlaceDetail.fromMap(Map<String, dynamic> map) {
    return PlaceDetail(
      name: map['name'] ?? 'Unknown Place',
      formattedAddress: map['formatted_address'],
      photoReferences: List<String>.from(map['photo_references'] ?? []),
      rating: map['rating']?.toDouble(),
      openingHours: map['opening_hours'],
      website: map['website'],
      priceLevel: map['price_level'],
      description: map['description'],
      types: List<String>.from(map['types'] ?? []),
    );
  }

  String get priceLevelString {
    if (priceLevel == null) return '';
    return '€' * priceLevel!;
  }

  String? get todayHours {
    if (openingHours == null || openingHours!['weekday_text'] == null) return null;
    final List<String> weekdayText = List<String>.from(openingHours!['weekday_text']);
    // Weekday text is usually Monday-Sunday.
    // We need to find today's hours.
    final now = DateTime.now();
    // In Google Places, Sunday is index 0 in some contexts, but in weekday_text it's often a fixed list.
    // Usually: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
    // DateTime.weekday: 1=Mon, ..., 7=Sun
    int dayIndex = now.weekday - 1;
    if (dayIndex >= 0 && dayIndex < weekdayText.length) {
      // The format is "Monday: 9:00 AM – 5:00 PM"
      final parts = weekdayText[dayIndex].split(': ');
      if (parts.length > 1) return parts[1];
    }
    return null;
  }
}
