import 'dart:math';
import '../models/ai_models.dart';
import '../models/models.dart';
import 'ai/gap_filler.dart';
import 'ai/opening_hours_validator.dart';
import 'ai/optimization_engine.dart';
import 'ai/time_budget_validator.dart';
import 'user_preference_service.dart';
import 'visited_places_registry.dart';

/// The core AI Travel Assistant engine.
///
/// This service orchestrates the generation pipeline:
/// 1. Data Fetching (Mock Place Database)
/// 2. Filtering (Cross-trip memory, rejected types, toggle-based)
/// 3. Ranking (Optimization Engine: Geo, Preference, Popularity, Toggle weights)
/// 4. Validation (Time Budget, Opening Hours)
/// 5. Enhancement (Gap Filler, Confidence Labels, Spontaneity trim)
class AiTripService {
  final UserPreferenceService _prefs;
  final VisitedPlacesRegistry _visitedRegistry;

  AiTripService(this._prefs, this._visitedRegistry);

  /// Generates a list of suggested activities for a specific trip and day.
  Future<List<AiSuggestion>> generateDailyItinerary({
    required Trip trip,
    required int dayIndex,
    required AiGenerationOptions options,
    RegenerationStyle? style,
    String? anchorTime, // Override day start (e.g. 10:00)
  }) async {
    // 1. Fetch relevant places based on trip location
    final city = trip.city ?? trip.country;
    print('AI: Generating itinerary for $city, Day $dayIndex');

    final rawPlaces = _getMockPlaces(city);
    print('AI: Found ${rawPlaces.length} raw candidates for $city');

    // 2. Filter: visited places, rejected types, and toggle-based exclusions
    final filtered = rawPlaces.where((p) {
      final id = p['placeId'] ?? p['name'];

      // Cross-trip memory: skip already visited places
      if (_visitedRegistry.isVisited(id)) {
        print('AI: Filtering out ${p['name']} (Already visited in registry)');
        return false;
      }
      if (_visitedRegistry.isVisitedByTitle(p['name'])) {
        print('AI: Filtering out ${p['name']} (Title match in registry)');
        return false;
      }

      // Skip repeatedly rejected place types
      final types = List<String>.from(p['types'] ?? []);
      if (types.any((t) => _prefs.shouldAvoidType(t))) {
        print(
            'AI: Filtering out ${p['name']} (Rejected type: ${types.firstWhere((t) => _prefs.shouldAvoidType(t))})');
        return false;
      }

      // ── Toggle-based hard filters ──────────────────────────────────────────
      // Food & Cafes toggles
      if (!options.includeRestaurants && p['category'] == 'Restaurant') {
        return false;
      }
      if (!options.includeCafes && p['category'] == 'Cafe') return false;

      // Family friendly: only allow explicitly family-safe places
      if (options.familyFriendly &&
          !(p['isFamilyFriendly'] as bool? ?? true)) {
        return false;
      }

      // Must-See Landmarks disabled: skip pure generic POIs with low popularity
      if (!options.focusPopular) {
        final popularity = (p['popularity'] as num?)?.toDouble() ?? 4.0;
        final ptypes = List<String>.from(p['types'] ?? []);
        if (ptypes.length == 1 &&
            ptypes.first == 'point_of_interest' &&
            popularity < 4.5) {
          return false;
        }
      }

      return true;
    }).toList();

    print('AI: ${filtered.length} candidates left after filtering');

    // 3. Convert to AiSuggestion models
    final suggestions = filtered.map((p) => _mapToSuggestion(p)).toList();

    // 4. Rank & Optimize — pass options so engine can apply toggle weights
    double? anchorLat;
    double? anchorLng;

    // Find the current day to use its last activity as geo anchor
    final currentDay = trip.days.firstWhere(
      (d) => d.dayIndex == dayIndex,
      orElse: () => trip.days.isNotEmpty
          ? trip.days[0]
          : TripDay(dayIndex: dayIndex, date: DateTime.now()),
    );

    if (currentDay.activities.isNotEmpty) {
      final last = currentDay.activities.last;
      anchorLat = last.lat;
      anchorLng = last.lng;
    }

    var optimized = OptimizationEngine.rank(
      suggestions: suggestions,
      categoryWeights: _prefs.getWeightedCategoryScores(),
      anchorLat: anchorLat,
      anchorLng: anchorLng,
      options: options,
    );

    // Apply regeneration styles (if user requested a restyle)
    if (style != null) {
      optimized = _applyStyle(optimized, style);
    }

    // 5. Validate Time Budget (trims if too many activities for one day)
    final budgetResult = TimeBudgetValidator.validate(
      optimized,
      dayStartTime: anchorTime ?? "09:00",
    );
    var validated = budgetResult.suggestions;

    // Spontaneity / Leave Room: trim to a lighter schedule (max 3 suggestions)
    if (options.leaveFreetime && validated.length > 3) {
      validated = validated.take(3).toList();
    }

    // 6. Fill Gaps (add travel buffers / free time placeholders)
    validated = GapFiller.fill(
      suggestions: validated,
      dayStartTime: anchorTime ?? "09:00",
      anchorLat: anchorLat,
      anchorLng: anchorLng,
    );

    // 7. Final Validation & Confidence labelling
    final withHours = OpeningHoursValidator.validate(validated);
    final finalResult = ConfidenceLabelAssigner.assignAll(
      suggestions: withHours,
      categoryWeights: _prefs.getWeightedCategoryScores(),
    );

    return finalResult;
  }

  // ---------------------------------------------------------------------------
  // Styles & Mapping
  // ---------------------------------------------------------------------------

  List<AiSuggestion> _applyStyle(
      List<AiSuggestion> list, RegenerationStyle style) {
    switch (style) {
      case RegenerationStyle.different:
        return list.reversed.toList();
      case RegenerationStyle.moreRelaxed:
        return list.where((s) => s.estimatedDuration <= 60).toList();
      case RegenerationStyle.moreLocal:
        return list.where((s) => s.popularityScore < 4.5).toList();
      case RegenerationStyle.morePopular:
        return list
          ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    }
  }

  AiSuggestion _mapToSuggestion(Map<String, dynamic> p) {
    return AiSuggestion(
      id: p['placeId'] ?? Random().nextInt(99999).toString(),
      name: p['name'],
      category: p['category'],
      imageUrl: p['imageUrl'],
      lat: p['lat'],
      lng: p['lng'],
      address: p['address'],
      placeId: p['placeId'],
      estimatedDuration: p['duration'] ?? 90,
      explanation: p['explanation'] ?? 'Highly rated among travelers like you.',
      popularityScore: (p['popularity'] as num?)?.toDouble() ?? 4.0,
      types: List<String>.from(p['types'] ?? []),
      confidence: AiConfidence.greatMatch,
      isLocalGem: p['isLocalGem'] as bool? ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Mock Place Database (Simulating a Places API)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _getMockPlaces(String? city) {
    final database = <String, List<Map<String, dynamic>>>{
      'London': [
        {
          'name': 'The British Museum',
          'placeId': 'ldn_bm',
          'category': 'Museum',
          'lat': 51.5194,
          'lng': -0.1270,
          'duration': 180,
          'popularity': 4.9,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1000',
        },
        {
          'name': 'Borough Market',
          'placeId': 'ldn_bmkt',
          'category': 'Market',
          'lat': 51.5055,
          'lng': -0.0910,
          'duration': 90,
          'popularity': 4.7,
          'types': ['food', 'point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?q=80&w=1000',
        },
        {
          'name': 'Sky Garden',
          'placeId': 'ldn_sg',
          'category': 'Viewpoint',
          'lat': 51.5111,
          'lng': -0.0837,
          'duration': 60,
          'popularity': 4.6,
          'types': ['park', 'point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000',
        },
        {
          'name': 'Dishoom Covent Garden',
          'placeId': 'ldn_dish',
          'category': 'Restaurant',
          'lat': 51.5124,
          'lng': -0.1268,
          'duration': 75,
          'popularity': 4.8,
          'types': ['restaurant', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000',
        },
        {
          'name': 'Tate Modern',
          'placeId': 'ldn_tm',
          'category': 'Art Gallery',
          'lat': 51.5076,
          'lng': -0.0994,
          'duration': 120,
          'popularity': 4.5,
          'types': ['art_gallery'],
          'isFamilyFriendly': false,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1549490349-8643362247b5?q=80&w=1000',
        },
        {
          'name': "St. Paul's Cathedral",
          'placeId': 'ldn_spc',
          'category': 'Historical Site',
          'lat': 51.5138,
          'lng': -0.0984,
          'duration': 90,
          'popularity': 4.7,
          'types': ['church', 'place_of_worship'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Monmouth Coffee',
          'placeId': 'ldn_mc',
          'category': 'Cafe',
          'lat': 51.5144,
          'lng': -0.1264,
          'duration': 30,
          'popularity': 4.6,
          'types': ['cafe', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
        },
        {
          'name': 'Maltby Street Market',
          'placeId': 'ldn_msm',
          'category': 'Market',
          'lat': 51.5010,
          'lng': -0.0820,
          'duration': 60,
          'popularity': 4.3,
          'types': ['food', 'point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'A hidden local market loved by Londoners',
        },
        {
          'name': 'Victoria and Albert Museum',
          'placeId': 'ldn_vam',
          'category': 'Museum',
          'lat': 51.4966,
          'lng': -0.1722,
          'duration': 150,
          'popularity': 4.8,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=1000',
        },
      ],
      'Paris': [
        {
          'name': 'Louvre Museum',
          'placeId': 'par_lou',
          'category': 'Museum',
          'lat': 48.8606,
          'lng': 2.3376,
          'duration': 240,
          'popularity': 4.9,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1543349689-9a4d426bee8e?q=80&w=1000',
        },
        {
          'name': 'Tuileries Garden',
          'placeId': 'par_tui',
          'category': 'Park',
          'lat': 48.8635,
          'lng': 2.3275,
          'duration': 60,
          'popularity': 4.6,
          'types': ['park'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Le Comptoir de La Gastronomie',
          'placeId': 'par_lcg',
          'category': 'Restaurant',
          'lat': 48.8643,
          'lng': 2.3441,
          'duration': 90,
          'popularity': 4.5,
          'types': ['restaurant', 'food'],
          'isFamilyFriendly': false,
          'isLocalGem': true,
        },
        {
          'name': 'Sainte-Chapelle',
          'placeId': 'par_sch',
          'category': 'Historical Site',
          'lat': 48.8555,
          'lng': 2.3450,
          'duration': 45,
          'popularity': 4.8,
          'types': ['church'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Café de Flore',
          'placeId': 'par_cdf',
          'category': 'Cafe',
          'lat': 48.8542,
          'lng': 2.3328,
          'duration': 60,
          'popularity': 4.2,
          'types': ['cafe', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
        },
        {
          'name': 'Musée d\'Orsay',
          'placeId': 'par_mdo',
          'category': 'Museum',
          'lat': 48.8600,
          'lng': 2.3266,
          'duration': 180,
          'popularity': 4.8,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=1000',
        },
        {
          'name': 'Montmartre Village',
          'placeId': 'par_mmt',
          'category': 'Neighborhood',
          'lat': 48.8867,
          'lng': 2.3431,
          'duration': 90,
          'popularity': 4.4,
          'types': ['point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'Charming artist village adored by locals',
        },
      ],
      'New York': [
        {
          'name': 'Central Park',
          'placeId': 'nyc_cp',
          'category': 'Park',
          'lat': 40.7851,
          'lng': -73.9683,
          'duration': 120,
          'popularity': 4.9,
          'types': ['park'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?q=80&w=1000',
        },
        {
          'name': 'The Metropolitan Museum of Art',
          'placeId': 'nyc_met',
          'category': 'Museum',
          'lat': 40.7794,
          'lng': -73.9632,
          'duration': 180,
          'popularity': 4.8,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Katz\'s Delicatessen',
          'placeId': 'nyc_katz',
          'category': 'Restaurant',
          'lat': 40.7223,
          'lng': -73.9873,
          'duration': 60,
          'popularity': 4.6,
          'types': ['restaurant', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'Iconic NYC deli, a true local institution since 1888',
        },
        {
          'name': 'Brooklyn Bridge',
          'placeId': 'nyc_bb',
          'category': 'Landmark',
          'lat': 40.7061,
          'lng': -73.9969,
          'duration': 60,
          'popularity': 4.7,
          'types': ['point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Smorgasburg',
          'placeId': 'nyc_smorg',
          'category': 'Market',
          'lat': 40.7222,
          'lng': -73.9572,
          'duration': 90,
          'popularity': 4.5,
          'types': ['food', 'point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'Brooklyn\'s beloved outdoor food market',
        },
        {
          'name': 'Blue Bottle Coffee Williamsburg',
          'placeId': 'nyc_bbc',
          'category': 'Cafe',
          'lat': 40.7140,
          'lng': -73.9612,
          'duration': 45,
          'popularity': 4.4,
          'types': ['cafe', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
        },
      ],
      'Tokyo': [
        {
          'name': 'Senso-ji Temple',
          'placeId': 'tky_ssj',
          'category': 'Historical Site',
          'lat': 35.7148,
          'lng': 139.7967,
          'duration': 90,
          'popularity': 4.8,
          'types': ['place_of_worship'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1000',
        },
        {
          'name': 'Tsukiji Outer Market',
          'placeId': 'tky_tsuk',
          'category': 'Market',
          'lat': 35.6654,
          'lng': 139.7707,
          'duration': 90,
          'popularity': 4.7,
          'types': ['food', 'point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'Tokyo\'s legendary fish market, a foodie paradise',
        },
        {
          'name': 'Shinjuku Gyoen',
          'placeId': 'tky_sgyoen',
          'category': 'Park',
          'lat': 35.6852,
          'lng': 139.7100,
          'duration': 90,
          'popularity': 4.6,
          'types': ['park'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Yanaka Ginza',
          'placeId': 'tky_ynk',
          'category': 'Neighborhood',
          'lat': 35.7270,
          'lng': 139.7687,
          'duration': 60,
          'popularity': 4.3,
          'types': ['point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
          'explanation': 'Old-town Tokyo, untouched by modernity — a local secret',
        },
      ],
      'Global': [
        {
          'name': 'City Main Square',
          'placeId': 'glb_ms',
          'category': 'Landmark',
          'lat': 0.0,
          'lng': 0.0,
          'duration': 45,
          'popularity': 5.0,
          'types': ['point_of_interest'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
          'imageUrl':
              'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?q=80&w=1000',
        },
        {
          'name': 'Modern Art Museum',
          'placeId': 'glb_mam',
          'category': 'Museum',
          'lat': 0.005,
          'lng': 0.005,
          'duration': 120,
          'popularity': 4.8,
          'types': ['museum'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Local Specialty Coffee',
          'placeId': 'glb_lsc',
          'category': 'Cafe',
          'lat': -0.005,
          'lng': -0.005,
          'duration': 45,
          'popularity': 4.5,
          'types': ['cafe', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': true,
        },
        {
          'name': 'Traditional Family Restaurant',
          'placeId': 'glb_tfr',
          'category': 'Restaurant',
          'lat': 0.01,
          'lng': 0.01,
          'duration': 90,
          'popularity': 4.7,
          'types': ['restaurant', 'food'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Grand Botanical Garden',
          'placeId': 'glb_gbg',
          'category': 'Park',
          'lat': -0.01,
          'lng': 0.01,
          'duration': 60,
          'popularity': 4.4,
          'types': ['park'],
          'isFamilyFriendly': true,
          'isLocalGem': false,
        },
        {
          'name': 'Hidden Rooftop Bar',
          'placeId': 'glb_hrb',
          'category': 'Bar',
          'lat': 0.008,
          'lng': -0.008,
          'duration': 60,
          'popularity': 4.2,
          'types': ['bar', 'food'],
          'isFamilyFriendly': false,
          'isLocalGem': true,
          'explanation': 'A locals-only rooftop spot with stunning city views',
        },
      ],
    };

    if (city == null || city.isEmpty) return database['Global']!;

    // Match city to database key (exact or substring)
    final key = database.keys.firstWhere(
      (k) =>
          k.toLowerCase() == city.toLowerCase() ||
          city.toLowerCase().contains(k.toLowerCase()),
      orElse: () => 'Global',
    );

    return database[key]!;
  }
}
