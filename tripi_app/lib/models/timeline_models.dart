import 'models.dart';

enum TravelPurpose {
  relaxation,
  romantic,
  adventure,
  culture,
  food,
  nightlife,
  shopping,
  nature,
  familyFriendly,
  workation
}

enum BudgetType { budget, midRange, luxury, flexible }

enum CabinClass { economy, premiumEconomy, business, first }

class Airport {
  final String airportName;
  final String city;
  final String country;
  final String iataCode;

  const Airport({
    required this.airportName,
    required this.city,
    required this.country,
    required this.iataCode,
  });

  String get displayName => '$iataCode · $city, $country';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return airportName.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        country.toLowerCase().contains(q) ||
        iataCode.toLowerCase().contains(q);
  }

  Map<String, dynamic> toJson() {
    return {
      'airportName': airportName,
      'city': city,
      'country': country,
      'iataCode': iataCode,
    };
  }

  static Airport? fromTravelContextJson(Map<String, dynamic> json) {
    final iata = json['origin_airport_iata']?.toString();
    if (iata == null || iata.isEmpty) return null;
    return Airport(
      airportName: json['origin_airport_name']?.toString() ?? iata,
      city: json['origin_city']?.toString() ?? '',
      country: json['origin_country']?.toString() ?? '',
      iataCode: iata.toUpperCase(),
    );
  }
}

class TravelIntent {
  final Airport? originAirport;
  final int adults;
  final List<int> childAges;
  final int infants;
  final TravelPurpose purpose;
  final BudgetType budgetPreference;
  final CabinClass cabinClass;
  final bool isFlexibleDates;

  const TravelIntent({
    this.originAirport,
    this.adults = 1,
    this.childAges = const [],
    this.infants = 0,
    this.purpose = TravelPurpose.relaxation,
    this.budgetPreference = BudgetType.flexible,
    this.cabinClass = CabinClass.economy,
    this.isFlexibleDates = false,
  });

  String get origin => originAirport?.iataCode ?? '';
  int get children => childAges.length;
  int get totalTravelers => adults + children + infants;

  TravelIntent normalized() {
    return copyWith(
      adults: adults < 1 ? 1 : adults,
      childAges: childAges.map((age) => age.clamp(0, 17).toInt()).toList(),
    );
  }

  TravelIntent copyWith({
    Airport? originAirport,
    bool clearOriginAirport = false,
    int? adults,
    List<int>? childAges,
    int? infants,
    TravelPurpose? purpose,
    BudgetType? budgetPreference,
    CabinClass? cabinClass,
    bool? isFlexibleDates,
  }) {
    return TravelIntent(
      originAirport:
          clearOriginAirport ? null : originAirport ?? this.originAirport,
      adults: adults ?? this.adults,
      childAges: childAges ?? this.childAges,
      infants: infants ?? this.infants,
      purpose: purpose ?? this.purpose,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      cabinClass: cabinClass ?? this.cabinClass,
      isFlexibleDates: isFlexibleDates ?? this.isFlexibleDates,
    );
  }

  factory TravelIntent.fromTravelContextJson(Map<String, dynamic> json) {
    final rawAges = json['child_ages'];
    final childAges = rawAges is List
        ? rawAges
            .map((age) => int.tryParse(age.toString()))
            .whereType<int>()
            .toList()
        : <int>[];

    T enumByName<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      final name = raw?.toString();
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => fallback,
      );
    }

    return TravelIntent(
      originAirport: Airport.fromTravelContextJson(json),
      adults: int.tryParse(json['adults_count']?.toString() ?? '') ?? 1,
      childAges: childAges,
      purpose: enumByName(
        TravelPurpose.values,
        json['trip_purpose'],
        TravelPurpose.relaxation,
      ),
      budgetPreference: enumByName(
        BudgetType.values,
        json['budget_type'],
        BudgetType.flexible,
      ),
      cabinClass: enumByName(
        CabinClass.values,
        json['cabin_class'],
        CabinClass.economy,
      ),
      isFlexibleDates: json['flexible_dates'] == true,
    );
  }

  Map<String, dynamic> toTravelContextJson(String userId) {
    return {
      'user_id': userId,
      'origin_airport_iata': originAirport?.iataCode,
      'origin_airport_name': originAirport?.airportName,
      'origin_city': originAirport?.city,
      'origin_country': originAirport?.country,
      'adults_count': adults,
      'children_count': children,
      'child_ages': childAges,
      'trip_purpose': purpose.name,
      'budget_type': budgetPreference.name,
      'cabin_class': cabinClass.name,
      'flexible_dates': isFlexibleDates,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class RankedDestinationRecommendation {
  final Destination destination;
  final double score;
  final List<String> reasons;
  final bool isFallback;

  const RankedDestinationRecommendation({
    required this.destination,
    required this.score,
    required this.reasons,
    this.isFallback = false,
  });
}

class FlightData {
  final double averagePrice;
  final String currency;
  final String trend; // 'up', 'down', 'stable'
  final List<String> popularAirlines;
  final String? bestTimeToBook;
  final int directFlightCount;

  FlightData({
    required this.averagePrice,
    this.currency = 'USD',
    this.trend = 'stable',
    this.popularAirlines = const [],
    this.bestTimeToBook,
    this.directFlightCount = 1,
  });

  String get priceTrend => trend;

  factory FlightData.fromJson(Map<String, dynamic> json) {
    return FlightData(
      averagePrice: (json['average_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      trend: json['trend']?.toString() ?? 'stable',
      popularAirlines: (json['popular_airlines'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bestTimeToBook: json['best_time_to_book']?.toString(),
      directFlightCount:
          int.tryParse(json['direct_flight_count']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_price': averagePrice,
      'currency': currency,
      'trend': trend,
      'popular_airlines': popularAirlines,
      'best_time_to_book': bestTimeToBook,
      'direct_flight_count': directFlightCount,
    };
  }
}

class HotelData {
  final double averageNightlyRate;
  final String currency;
  final int availabilityScore; // 0 to 100
  final String bookingTrend;
  final List<String> bestNeighborhoods;

  HotelData({
    required this.averageNightlyRate,
    this.currency = 'USD',
    this.availabilityScore = 100,
    this.bookingTrend = 'moderate',
    this.bestNeighborhoods = const [],
  });

  double get averagePricePerNight => averageNightlyRate;

  factory HotelData.fromJson(Map<String, dynamic> json) {
    return HotelData(
      averageNightlyRate:
          (json['average_nightly_rate'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      availabilityScore:
          int.tryParse(json['availability_score']?.toString() ?? '') ?? 100,
      bookingTrend: json['booking_trend']?.toString() ?? 'moderate',
      bestNeighborhoods: (json['best_neighborhoods'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_nightly_rate': averageNightlyRate,
      'currency': currency,
      'availability_score': availabilityScore,
      'booking_trend': bookingTrend,
      'best_neighborhoods': bestNeighborhoods,
    };
  }
}

class WeatherData {
  final double averageHigh;
  final double averageLow;
  final String condition; // 'sunny', 'rainy', 'cloudy'
  final int rainfallDays;

  WeatherData({
    required this.averageHigh,
    required this.averageLow,
    required this.condition,
    this.rainfallDays = 0,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      averageHigh: (json['average_high'] as num?)?.toDouble() ?? 0.0,
      averageLow: (json['average_low'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition']?.toString() ?? 'sunny',
      rainfallDays: int.tryParse(json['rainfall_days']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_high': averageHigh,
      'average_low': averageLow,
      'condition': condition,
      'rainfall_days': rainfallDays,
    };
  }
}

class DestinationInsight {
  final String id;
  final Destination destination;
  final int month;
  final FlightData flightData;
  final HotelData hotelData;
  final WeatherData weatherData;
  final String popularity;
  final String crowdLevels;
  final Map<String, dynamic> recommendationScores;
  final String aiInsight;
  final DateTime updatedAt;

  DestinationInsight({
    required this.id,
    required this.destination,
    required this.month,
    required this.flightData,
    required this.hotelData,
    required this.weatherData,
    this.popularity = 'high',
    this.crowdLevels = 'moderate',
    this.recommendationScores = const {},
    this.aiInsight = '',
    required this.updatedAt,
  });

  factory DestinationInsight.fromJson(
      Map<String, dynamic> json, Destination dest) {
    return DestinationInsight(
      id: json['id']?.toString() ?? '',
      destination: dest,
      month: int.tryParse(json['month']?.toString() ?? '') ?? 1,
      flightData: FlightData.fromJson(
          Map<String, dynamic>.from(json['pricing_data']?['flight'] ?? {})),
      hotelData: HotelData.fromJson(
          Map<String, dynamic>.from(json['pricing_data']?['hotel'] ?? {})),
      weatherData: WeatherData.fromJson(
          Map<String, dynamic>.from(json['weather_data'] ?? {})),
      popularity: json['popularity']?.toString() ?? 'high',
      crowdLevels: json['crowd_levels']?.toString() ?? 'moderate',
      recommendationScores:
          Map<String, dynamic>.from(json['recommendation_scores'] ?? {}),
      aiInsight: json['ai_insight']?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination_name': destination.name,
      'month': month,
      'pricing_data': {
        'flight': flightData.toJson(),
        'hotel': hotelData.toJson(),
      },
      'weather_data': weatherData.toJson(),
      'popularity': popularity,
      'crowd_levels': crowdLevels,
      'recommendation_scores': recommendationScores,
      'ai_insight': aiInsight,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DestinationInsight copyWith({
    String? id,
    Destination? destination,
    int? month,
    FlightData? flightData,
    HotelData? hotelData,
    WeatherData? weatherData,
    String? popularity,
    String? crowdLevels,
    Map<String, dynamic>? recommendationScores,
    String? aiInsight,
    DateTime? updatedAt,
  }) {
    return DestinationInsight(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      month: month ?? this.month,
      flightData: flightData ?? this.flightData,
      hotelData: hotelData ?? this.hotelData,
      weatherData: weatherData ?? this.weatherData,
      popularity: popularity ?? this.popularity,
      crowdLevels: crowdLevels ?? this.crowdLevels,
      recommendationScores: recommendationScores ?? this.recommendationScores,
      aiInsight: aiInsight ?? this.aiInsight,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
