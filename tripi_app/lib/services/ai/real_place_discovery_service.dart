import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/ai_models.dart';
import '../../models/models.dart';
import '../places_service.dart';

/// Fetches **real** places from Google Places API, groups them into the three
/// recommendation sections (Landmarks, Local Gems, Food & Drinks), and applies
/// toggle-aware filtering so every user option directly controls discovery.
///
/// Discovery pipeline:
///   1. Resolve city-centre coordinates
///   2. Run parallel searches — queries depend on active toggles
///   3. Deduplicate by placeId
///   4. Filter: rating/review thresholds + geographic mode guard
///   5. Classify each place into Landmark / LocalGem / Food
///   6. Convert to internal map + generate AI explanations
///   7. Cache result per (cityKey, optionsKey)
class RealPlaceDiscoveryService {
  final PlacesService _places;

  RealPlaceDiscoveryService(this._places);

  // ── Session cache ─────────────────────────────────────────────────────────
  final Map<String, AiRecommendationSet> _groupedCache = {};
  // Legacy flat cache kept for any remaining callers
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  void clearCache() {
    _groupedCache.clear();
    _cache.clear();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a grouped [AiRecommendationSet] driven entirely by [options].
  Future<AiRecommendationSet> fetchGroupedPlaces(
    Trip trip,
    AiGenerationOptions options,
  ) async {
    final cacheKey = _cacheKey(trip, options);
    if (_groupedCache.containsKey(cacheKey)) {
      debugPrint('RealDiscovery: Cache hit for $cacheKey');
      return _groupedCache[cacheKey]!;
    }

    // 1. Resolve city centre
    final centre = await _resolveCityCentre(trip);
    if (centre == null) {
      debugPrint(
          'RealDiscovery: Could not resolve city centre for ${trip.city}');
      return const AiRecommendationSet(
          landmarks: [], localGems: [], food: []);
    }

    final cityLat = centre['lat'] as double;
    final cityLng = centre['lng'] as double;
    final cityName = trip.city ?? trip.country;
    final isOutside = options.explorationStyle == ExplorationStyle.outsideCity;

    debugPrint(
        'RealDiscovery: Grouped search around $cityName ($cityLat, $cityLng) — style=${options.explorationStyle.name}');

    // 2. Run parallel searches, split by section
    final landmarkResults = await _fetchLandmarkCandidates(
      cityLat: cityLat,
      cityLng: cityLng,
      isOutside: isOutside,
      options: options,
    );

    final gemResults = options.localGems
        ? await _fetchLocalGemCandidates(
            cityLat: cityLat,
            cityLng: cityLng,
            isOutside: isOutside,
          )
        : <Map<String, dynamic>>[];

    final foodResults = (options.includeRestaurants || options.includeCafes)
        ? await _fetchFoodCandidates(
            cityLat: cityLat,
            cityLng: cityLng,
            isOutside: isOutside,
            includeRestaurants: options.includeRestaurants,
            includeCafes: options.includeCafes,
          )
        : <Map<String, dynamic>>[];

    debugPrint(
        'RealDiscovery: Raw — landmarks=${landmarkResults.length}, gems=${gemResults.length}, food=${foodResults.length}');

    // 3. Filter by geographic bounds + quality thresholds
    final filteredLandmarks = _filterResults(
      landmarkResults,
      isOutside: isOutside,
      cityLat: cityLat,
      cityLng: cityLng,
      minReviews: options.focusPopular ? 300 : 50,
    );

    final filteredGems = _filterResults(
      gemResults,
      isOutside: isOutside,
      cityLat: cityLat,
      cityLng: cityLng,
      minReviews: 20,
      maxReviews: 500, // Local gems: not too famous
      minRating: 4.3,
    );

    final filteredFood = _filterResults(
      foodResults,
      isOutside: isOutside,
      cityLat: cityLat,
      cityLng: cityLng,
      minReviews: 30,
    );

    debugPrint(
        'RealDiscovery: Filtered — landmarks=${filteredLandmarks.length}, gems=${filteredGems.length}, food=${filteredFood.length}');

    // 4. Fallback expansion when too few results
    final finalLandmarks = filteredLandmarks.length < 4
        ? await _expandFallback(filteredLandmarks, landmarkResults, isOutside,
            cityLat, cityLng)
        : filteredLandmarks;

    // 5. Convert to AiSuggestion objects with section tags
    final landmarks = finalLandmarks
        .map((r) => _toSuggestion(r,
            cityName: cityName,
            isOutside: isOutside,
            section: RecommendationSection.landmark))
        .toList();

    final localGems = filteredGems
        .map((r) => _toSuggestion(r,
            cityName: cityName,
            isOutside: isOutside,
            section: RecommendationSection.localGem))
        .toList();

    final food = filteredFood
        .map((r) => _toSuggestion(r,
            cityName: cityName,
            isOutside: isOutside,
            section: RecommendationSection.food))
        .toList();

    final result = AiRecommendationSet(
      landmarks: landmarks,
      localGems: localGems,
      food: food,
    );

    _groupedCache[cacheKey] = result;
    return result;
  }

  /// Legacy flat fetcher — still used by the old AiTripService path.
  Future<List<Map<String, dynamic>>> fetchPlaces(
    Trip trip,
    AiGenerationOptions options,
  ) async {
    final grouped = await fetchGroupedPlaces(trip, options);
    return grouped.allSuggestions
        .map((s) => _suggestionToMap(s))
        .toList();
  }

  // ── Cache Key ──────────────────────────────────────────────────────────────

  String _cacheKey(Trip trip, AiGenerationOptions options) {
    final base = trip.cityPlaceId ?? trip.city ?? trip.country;
    final flags = [
      options.explorationStyle.name,
      'pop${options.focusPopular}',
      'gem${options.localGems}',
      'fam${options.familyFriendly}',
      'rst${options.includeRestaurants}',
      'cfe${options.includeCafes}',
    ].join('_');
    return '${base}_$flags';
  }

  // ── Section-specific Search Strategies ────────────────────────────────────

  /// Landmarks: iconic tourist attractions, museums, monuments, castles, etc.
  Future<List<Map<String, dynamic>>> _fetchLandmarkCandidates({
    required double cityLat,
    required double cityLng,
    required bool isOutside,
    required AiGenerationOptions options,
  }) async {
    final futures = <Future<List<Map<String, dynamic>>>>[];

    if (!isOutside) {
      // ── Inside city ────────────────────────────────────────────────────────
      const radius = 12000;
      final types = [
        'tourist_attraction',
        'museum',
        'art_gallery',
        'park',
        'place_of_worship',
      ];
      for (final type in types) {
        futures.add(_search(lat: cityLat, lng: cityLng, type: type, radius: radius));
      }
      // Keyword searches for things Google doesn't type-classify well
      for (final kw in ['historic landmark', 'monument', 'palace']) {
        futures.add(_search(lat: cityLat, lng: cityLng, keyword: kw, radius: radius));
      }
      // Family additions
      if (options.familyFriendly) {
        for (final type in ['zoo', 'aquarium', 'amusement_park']) {
          futures.add(_search(lat: cityLat, lng: cityLng, type: type, radius: radius));
        }
      }
    } else {
      // ── Outside city ───────────────────────────────────────────────────────
      const radius = 50000;
      final types = [
        'tourist_attraction',
        'amusement_park',
        'natural_feature',
        'park',
      ];
      for (final type in types) {
        futures.add(_search(lat: cityLat, lng: cityLng, type: type, radius: radius));
      }
      for (final kw in [
        'castle',
        'viewpoint',
        'scenic attraction',
        'historic town',
        'village',
        'waterfall',
        'national park',
        'theme park',
        'day trip',
      ]) {
        futures.add(_search(lat: cityLat, lng: cityLng, keyword: kw, radius: radius));
      }
      if (options.familyFriendly) {
        for (final kw in ['zoo', 'aquarium', 'amusement park']) {
          futures.add(_search(lat: cityLat, lng: cityLng, keyword: kw, radius: radius));
        }
      }
    }

    return _mergeResults(await Future.wait(futures));
  }

  /// Local Gems: high rating, lower review count (authentic, not touristy)
  Future<List<Map<String, dynamic>>> _fetchLocalGemCandidates({
    required double cityLat,
    required double cityLng,
    required bool isOutside,
  }) async {
    final radius = isOutside ? 40000 : 10000;
    final futures = <Future<List<Map<String, dynamic>>>>[];

    // Types that tend to produce local gems
    for (final type in ['tourist_attraction', 'museum', 'art_gallery', 'park']) {
      futures.add(_search(lat: cityLat, lng: cityLng, type: type, radius: radius));
    }
    for (final kw in [
      'local market',
      'hidden gem',
      'boutique',
      'underground art',
      'street art',
      'rooftop bar',
      'local cafe',
    ]) {
      futures.add(_search(lat: cityLat, lng: cityLng, keyword: kw, radius: radius));
    }

    return _mergeResults(await Future.wait(futures));
  }

  /// Food: restaurants and cafes depending on toggles
  Future<List<Map<String, dynamic>>> _fetchFoodCandidates({
    required double cityLat,
    required double cityLng,
    required bool isOutside,
    required bool includeRestaurants,
    required bool includeCafes,
  }) async {
    final radius = isOutside ? 40000 : 12000;
    final futures = <Future<List<Map<String, dynamic>>>>[];

    if (includeRestaurants) {
      futures.add(_search(lat: cityLat, lng: cityLng, type: 'restaurant', radius: radius));
      futures.add(_search(lat: cityLat, lng: cityLng, keyword: 'highly rated restaurant', radius: radius));
    }
    if (includeCafes) {
      futures.add(_search(lat: cityLat, lng: cityLng, type: 'cafe', radius: radius));
      futures.add(_search(lat: cityLat, lng: cityLng, type: 'bakery', radius: radius));
      futures.add(_search(lat: cityLat, lng: cityLng, keyword: 'scenic cafe', radius: radius));
    }

    return _mergeResults(await Future.wait(futures));
  }

  // ── City Centre Resolution ─────────────────────────────────────────────────

  Future<Map<String, double>?> _resolveCityCentre(Trip trip) async {
    if (trip.cityPlaceId != null && trip.cityPlaceId!.isNotEmpty) {
      final details = await _places.getPlaceDetailsRaw(trip.cityPlaceId!);
      if (details != null &&
          details['lat'] != null &&
          details['lng'] != null) {
        return {
          'lat': (details['lat'] as num).toDouble(),
          'lng': (details['lng'] as num).toDouble(),
        };
      }
    }

    final cityName = trip.city ?? trip.country;
    if (cityName.isEmpty) return null;

    try {
      final suggestions =
          await _places.autocompleteCities(cityName, trip.countryCode);
      if (suggestions.isEmpty) return null;

      final placeId = suggestions.first['place_id']?.toString();
      if (placeId == null || placeId.isEmpty) return null;

      final details = await _places.getPlaceDetailsRaw(placeId);
      if (details != null &&
          details['lat'] != null &&
          details['lng'] != null) {
        return {
          'lat': (details['lat'] as num).toDouble(),
          'lng': (details['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      debugPrint('RealDiscovery: Fallback geocode error: $e');
    }

    return null;
  }

  // ── Low-level Search ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _search({
    required double lat,
    required double lng,
    String? type,
    String? keyword,
    required int radius,
  }) async {
    try {
      final results = await _places.searchNearby(
        lat: lat,
        lng: lng,
        type: type,
        keyword: keyword,
        radius: radius,
        maxResults: 20,
      );
      return results
          .map((r) => {
                'placeId': r.placeId,
                'name': r.name,
                'lat': r.lat,
                'lng': r.lng,
                'address': r.address ?? r.formattedAddress,
                'rating': r.rating ?? 0.0,
                'userRatingsTotal': r.userRatingsTotal ?? 0,
                'types': r.types,
                'imageUrl': r.imageUrl,
                'openingHours': r.openingHours,
              })
          .toList();
    } catch (e) {
      debugPrint(
          'RealDiscovery: search error (type=$type keyword=$keyword): $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mergeResults(
      List<List<Map<String, dynamic>>> batches) {
    final merged = <String, Map<String, dynamic>>{};
    for (final batch in batches) {
      for (final place in batch) {
        final id = place['placeId'] as String? ?? '';
        if (id.isNotEmpty) merged[id] = place;
      }
    }
    return merged.values.toList();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filterResults(
    List<Map<String, dynamic>> raw, {
    required bool isOutside,
    required double cityLat,
    required double cityLng,
    double minRating = 3.5,
    int minReviews = 30,
    int? maxReviews,
  }) {
    const minOutsideDistKm = 5.0;
    const maxInsideDistKm = 15.0;

    const excludedTypes = {
      'locality',
      'political',
      'administrative_area_level_1',
      'administrative_area_level_2',
      'country',
      'postal_code',
      'route',
      'street_address',
    };

    return raw.where((p) {
      final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
      final reviews = (p['userRatingsTotal'] as num?)?.toInt() ?? 0;
      final types = List<String>.from(p['types'] as List? ?? []);

      if (rating < minRating) return false;
      if (reviews < minReviews) return false;
      if (maxReviews != null && reviews > maxReviews) return false;
      if (types.every((t) => excludedTypes.contains(t))) return false;

      final distKm = _haversine(
        cityLat,
        cityLng,
        (p['lat'] as num).toDouble(),
        (p['lng'] as num).toDouble(),
      );

      if (isOutside && distKm < minOutsideDistKm) return false;
      if (!isOutside && distKm > maxInsideDistKm) return false;

      return true;
    }).toList();
  }

  // ── Fallback Expansion ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _expandFallback(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> originalRaw,
    bool isOutside,
    double cityLat,
    double cityLng,
  ) async {
    debugPrint('RealDiscovery: Expanding fallback radius...');
    final seenIds = current.map((p) => p['placeId'] as String).toSet();

    // Relax thresholds to widen the net
    final relaxed = _filterResults(
      originalRaw,
      isOutside: isOutside,
      cityLat: cityLat,
      cityLng: cityLng,
      minRating: 3.0,
      minReviews: 10,
    );

    for (final p in relaxed) {
      final id = p['placeId'] as String? ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        current.add(p);
        seenIds.add(id);
      }
    }
    return current;
  }

  // ── Conversion ─────────────────────────────────────────────────────────────

  AiSuggestion _toSuggestion(
    Map<String, dynamic> raw, {
    required String? cityName,
    required bool isOutside,
    required RecommendationSection section,
  }) {
    final types = List<String>.from(raw['types'] as List? ?? []);
    final category = _inferCategory(types, section);
    final rating = (raw['rating'] as num?)?.toDouble() ?? 4.0;
    final reviews = (raw['userRatingsTotal'] as num?)?.toInt() ?? 0;
    final name = raw['name'] as String? ?? 'Place';
    final isLocalGem = section == RecommendationSection.localGem ||
        (reviews < 300 && rating >= 4.3);
    final isFamilyFriendly = _isFamilyFriendly(types);

    return AiSuggestion(
      id: raw['placeId'] as String? ?? Random().nextInt(999999).toString(),
      name: name,
      category: category,
      imageUrl: raw['imageUrl'] as String?,
      lat: (raw['lat'] as num?)?.toDouble(),
      lng: (raw['lng'] as num?)?.toDouble(),
      address: raw['address'] as String?,
      placeId: raw['placeId'] as String?,
      estimatedDuration: _estimateDuration(category),
      explanation: _generateExplanation(
        name: name,
        category: category,
        rating: rating,
        reviews: reviews,
        cityName: cityName ?? 'the city',
        isOutside: isOutside,
        isLocalGem: isLocalGem,
        isFamilyFriendly: isFamilyFriendly,
        section: section,
      ),
      popularityScore: rating.clamp(0.0, 5.0),
      userRatingsTotal: reviews,
      types: types,
      confidence: AiConfidence.greatMatch, // Re-set by OptimizationEngine
      isLocalGem: isLocalGem,
      section: section,
      recommendationScore: 50.0, // Placeholder, set by OptimizationEngine
    );
  }

  /// Convert an AiSuggestion back to the legacy map format
  Map<String, dynamic> _suggestionToMap(AiSuggestion s) => {
        'placeId': s.placeId,
        'name': s.name,
        'category': s.category,
        'lat': s.lat,
        'lng': s.lng,
        'address': s.address,
        'imageUrl': s.imageUrl,
        'types': s.types,
        'popularity': s.popularityScore,
        'userRatingsTotal': s.userRatingsTotal,
        'duration': s.estimatedDuration,
        'isFamilyFriendly': _isFamilyFriendly(s.types),
        'isLocalGem': s.isLocalGem,
        'explanation': s.explanation,
        'explorationStyle': s.section.name,
      };

  // ── Category Inference ─────────────────────────────────────────────────────

  String _inferCategory(List<String> types, RecommendationSection section) {
    if (section == RecommendationSection.food) {
      if (types.contains('restaurant')) return 'Restaurant';
      if (types.contains('cafe') || types.contains('bakery')) return 'Cafe';
      return 'Restaurant';
    }
    if (types.contains('museum')) return 'Museum';
    if (types.contains('art_gallery')) return 'Art Gallery';
    if (types.contains('amusement_park')) return 'Amusement Park';
    if (types.contains('zoo')) return 'Zoo';
    if (types.contains('aquarium')) return 'Aquarium';
    if (types.contains('park')) return 'Park';
    if (types.contains('natural_feature')) return 'Nature';
    if (types.contains('campground')) return 'Nature';
    if (types.contains('shopping_mall') || types.contains('store')) {
      return 'Shopping';
    }
    if (types.contains('place_of_worship') ||
        types.contains('church') ||
        types.contains('mosque') ||
        types.contains('synagogue')) {
      return 'Historical Site';
    }
    if (types.contains('tourist_attraction')) return 'Landmark';
    if (types.contains('restaurant')) return 'Restaurant';
    if (types.contains('cafe') || types.contains('bakery')) return 'Cafe';
    if (types.contains('bar') || types.contains('night_club')) return 'Bar';
    return 'Attraction';
  }

  bool _isFamilyFriendly(List<String> types) {
    const familySafe = {
      'park',
      'museum',
      'tourist_attraction',
      'amusement_park',
      'zoo',
      'aquarium',
      'natural_feature',
      'restaurant',
    };
    const notFamily = {'bar', 'night_club', 'casino'};
    if (types.any((t) => notFamily.contains(t))) return false;
    return types.any((t) => familySafe.contains(t));
  }

  int _estimateDuration(String category) {
    switch (category) {
      case 'Museum':
      case 'Art Gallery':
        return 150;
      case 'Historical Site':
        return 90;
      case 'Restaurant':
        return 75;
      case 'Cafe':
        return 45;
      case 'Park':
        return 90;
      case 'Nature':
        return 120;
      case 'Landmark':
      case 'Attraction':
        return 60;
      case 'Shopping':
        return 90;
      case 'Bar':
        return 60;
      case 'Amusement Park':
      case 'Zoo':
      case 'Aquarium':
        return 180;
      default:
        return 60;
    }
  }

  // ── AI Explanation Generator ───────────────────────────────────────────────

  String _generateExplanation({
    required String name,
    required String category,
    required double rating,
    required int reviews,
    required String cityName,
    required bool isOutside,
    required bool isLocalGem,
    required bool isFamilyFriendly,
    required RecommendationSection section,
  }) {
    final ratingStr = rating.toStringAsFixed(1);
    final reviewsStr = _formatNumber(reviews);

    switch (section) {
      case RecommendationSection.landmark:
        if (isOutside) {
          if (reviews >= 5000) {
            return 'A world-famous day-trip from $cityName — $reviews+ visitors and a stunning $ratingStr★ rating. Don\'t miss it.';
          }
          if (category == 'Nature') {
            return 'A breathtaking natural escape just outside $cityName, rated $ratingStr★ by $reviewsStr visitors.';
          }
          return 'A top-rated destination just outside $cityName. $reviewsStr travelers gave it $ratingStr★ — perfect for a day trip.';
        }
        if (reviews >= 10000) {
          return 'One of the most iconic ${category.toLowerCase()} in $cityName, with $reviewsStr+ reviews and a $ratingStr★ rating.';
        }
        if (reviews >= 2000 && rating >= 4.5) {
          return 'Extremely popular with tourists — $ratingStr★ from $reviewsStr visitors in $cityName.';
        }
        return 'A must-visit $category in $cityName, praised by $reviewsStr travelers ($ratingStr★).';

      case RecommendationSection.localGem:
        if (isOutside) {
          return 'A local favourite outside $cityName that most tourists overlook. Rated $ratingStr★ by $reviewsStr people in the know.';
        }
        if (isFamilyFriendly) {
          return 'A beloved local spot in $cityName — great for families and rated $ratingStr★ by those who\'ve found it.';
        }
        return 'A hidden gem loved by $cityName locals. Only $reviewsStr reviews but an impressive $ratingStr★ — authentically local.';

      case RecommendationSection.food:
        if (category == 'Cafe') {
          if (isOutside) {
            return 'A charming cafe near $cityName with $ratingStr★ from $reviewsStr visitors — ideal for a relaxed break.';
          }
          return 'A top-rated cafe in $cityName ($ratingStr★ · $reviewsStr reviews) — popular with locals and travelers alike.';
        }
        if (reviews >= 3000) {
          return 'One of $cityName\'s most-visited restaurants, rated $ratingStr★ by $reviewsStr diners.';
        }
        return 'Highly rated ${category.toLowerCase()} in $cityName — $ratingStr★ from $reviewsStr visitors.';
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k+';
    return n.toString();
  }

  // ── Haversine ──────────────────────────────────────────────────────────────

  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
