enum PlaceSource { google, tripadvisor, internal }

class PlaceResult {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final int? priceLevel;
  final String? photoReference;
  final List<String> photoReferences;
  final String? imageUrl; // Full URL for display
  final PlaceSource source;
  final String? website;
  final Map<String, dynamic>? openingHours;
  final String? description;
  final String? countryCode;
  
  // Transient fields for discovery logic
  double? distance; // Distance from nearest anchor in meters
  double? score;    // Weighted discovery score

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.formattedAddress,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.priceLevel,
    this.photoReference,
    this.photoReferences = const [],
    this.imageUrl,
    this.source = PlaceSource.google,
    this.website,
    this.openingHours,
    this.description,
    this.countryCode,
    this.distance,
    this.score,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json, {PlaceSource source = PlaceSource.google, String? imageUrl}) {
    final photos = (json['photos'] != null && json['photos'] is List)
        ? List<String>.from(json['photos']
            .map((p) => p['photo_reference']?.toString())
            .where((p) => p != null))
        : <String>[];

    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      lat: json['geometry']?['location']?['lat']?.toDouble() ?? 0.0,
      lng: json['geometry']?['location']?['lng']?.toDouble() ?? 0.0,
      address: json['vicinity'] ?? json['formatted_address'],
      formattedAddress: json['formatted_address'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      priceLevel: json['price_level'],
      photoReference: photos.isNotEmpty ? photos[0] : null,
      photoReferences: photos,
      imageUrl: imageUrl,
      source: source,
      website: json['website'],
      openingHours: json['opening_hours'],
      description: json['editorial_summary']?['overview'],
      countryCode: json['country_code'],
    );
  }

  factory PlaceResult.fromMap(Map<String, dynamic> map) {
    return PlaceResult(
      placeId: map['place_id'] ?? '',
      name: map['name'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      address: map['formatted_address'] ?? map['address'],
      formattedAddress: map['formatted_address'],
      rating: map['rating']?.toDouble(),
      userRatingsTotal: map['user_ratings_total'],
      types: List<String>.from(map['types'] ?? []),
      priceLevel: map['price_level'],
      photoReferences: List<String>.from(map['photo_references'] ?? []),
      photoReference: (map['photo_references'] as List?)?.isNotEmpty == true 
          ? map['photo_references'][0] 
          : null,
      imageUrl: map['image_url'],
      source: PlaceSource.values.firstWhere(
        (e) => e.name == (map['source'] ?? 'google'),
        orElse: () => PlaceSource.google,
      ),
      website: map['website'],
      openingHours: map['opening_hours'],
      description: map['description'],
      countryCode: map['country_code'],
    );
  }

  String get priceLevelString {
    if (priceLevel == null) return '';
    return '€' * priceLevel!;
  }

  String? get todayHours {
    if (openingHours == null || openingHours!['weekday_text'] == null) {
      return null;
    }
    final List<String> weekdayText =
        List<String>.from(openingHours!['weekday_text']);
    final now = DateTime.now();
    int dayIndex = now.weekday - 1;
    if (dayIndex >= 0 && dayIndex < weekdayText.length) {
      final parts = weekdayText[dayIndex].split(': ');
      if (parts.length > 1) return parts[1];
    }
    return null;
  }

  PlaceResult copyWith({
    String? website,
    Map<String, dynamic>? openingHours,
    String? description,
    List<String>? photoReferences,
    String? imageUrl,
    double? distance,
    double? score,
  }) {
    return PlaceResult(
      placeId: placeId,
      name: name,
      lat: lat,
      lng: lng,
      address: address,
      formattedAddress: formattedAddress,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      types: types,
      priceLevel: priceLevel,
      photoReference: photoReference,
      photoReferences: photoReferences ?? this.photoReferences,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      description: description ?? this.description,
      countryCode: countryCode,
      distance: distance ?? this.distance,
      score: score ?? this.score,
    );
  }
}
