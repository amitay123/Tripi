class PlaceResult {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final int? priceLevel;
  final String? photoReference;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.priceLevel,
    this.photoReference,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      placeId: json['place_id'],
      name: json['name'],
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
      address: json['vicinity'] ?? json['formatted_address'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      priceLevel: json['price_level'],
      photoReference: (json['photos'] != null && json['photos'].isNotEmpty)
          ? json['photos'][0]['photo_reference']
          : null,
    );
  }
}
