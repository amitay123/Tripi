import '../../models/models.dart';
import '../../models/timeline_models.dart';

class TimelineDestinationProfile {
  final Destination destination;
  final String airportCode;
  final List<int> bestMonths;
  final List<int> shoulderMonths;
  final List<int> badMonths;
  final int minDays;
  final int maxDays;
  final Set<TravelPurpose> supportedPurposes;
  final Set<String> companionFit;
  final BudgetType budgetLevel;
  final Map<String, double> estimatedFlightPriceByOrigin;
  final double estimatedHotelNightlyPrice;
  final Map<int, double> weatherScoreByMonth;
  final Map<int, double> crowdLevelByMonth;
  final double safetyFamilyScore;
  final double nightlifeScore;
  final double cultureScore;
  final double foodScore;
  final double natureScore;
  final double romanceScore;
  final double relaxationScore;
  final double shoppingScore;
  final double workationScore;
  final double longHaulScore;
  final bool directFlightAvailabilityMock;

  const TimelineDestinationProfile({
    required this.destination,
    required this.airportCode,
    required this.bestMonths,
    required this.shoulderMonths,
    required this.badMonths,
    required this.minDays,
    required this.maxDays,
    required this.supportedPurposes,
    required this.companionFit,
    required this.budgetLevel,
    required this.estimatedFlightPriceByOrigin,
    required this.estimatedHotelNightlyPrice,
    required this.weatherScoreByMonth,
    required this.crowdLevelByMonth,
    required this.safetyFamilyScore,
    required this.nightlifeScore,
    required this.cultureScore,
    required this.foodScore,
    required this.natureScore,
    required this.romanceScore,
    required this.relaxationScore,
    required this.shoppingScore,
    required this.workationScore,
    required this.longHaulScore,
    required this.directFlightAvailabilityMock,
  });
}

class TimelineRecommendationService {
  static const _fallbackReason =
      'Showing popular options because your filters are very specific.';

  List<RankedDestinationRecommendation> rankDestinations({
    required TravelIntent intent,
    required int month,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    int? durationDays,
    int limit = 5,
  }) {
    final normalized = intent.normalized();
    final rankings = _profiles.map((profile) {
      return _scoreDestination(
        profile,
        normalized,
        month,
        durationDays,
        selectedStartDate,
        selectedEndDate,
      );
    }).toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.destination.name.compareTo(b.destination.name);
      });

    final top = rankings.take(limit).toList();
    if (top.isEmpty) return top;

    final strongest = top.first.score;
    if (strongest >= 32) return top;

    return top
        .map(
          (ranking) => RankedDestinationRecommendation(
            destination: ranking.destination,
            score: ranking.score,
            reasons: const [_fallbackReason],
            isFallback: true,
          ),
        )
        .toList();
  }

  RankedDestinationRecommendation _scoreDestination(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    int month,
    int? durationDays,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
  ) {
    double score = 0;
    final reasons = <String>[];

    score += _seasonScore(profile, intent, month, reasons);
    score += _durationScore(profile, durationDays, reasons);
    score += _purposeScore(profile, intent.purpose, reasons);
    score += _travelersScore(profile, intent, reasons);
    score += _budgetScore(profile, intent, reasons);
    score += _cabinScore(profile, intent, reasons);
    score += _originScore(profile, intent, reasons);
    score += _weatherCrowdScore(profile, intent, month, reasons);

    if (intent.isFlexibleDates) {
      score += 4;
      reasons.add('Flexible dates may unlock better flight prices.');
    }

    final seed = (selectedStartDate?.day ?? 0) +
        (selectedEndDate?.day ?? 0) +
        intent.totalTravelers +
        intent.purpose.index +
        intent.budgetPreference.index;
    score += (profile.destination.id.hashCode ^ seed).abs() % 5;

    return RankedDestinationRecommendation(
      destination: profile.destination,
      score: score,
      reasons: _shortReasons(reasons),
    );
  }

  double _seasonScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    int month,
    List<String> reasons,
  ) {
    if (profile.bestMonths.contains(month)) {
      reasons.add('Best weather during your selected dates.');
      return 18;
    }
    if (profile.shoulderMonths.contains(month)) {
      reasons.add('Good shoulder-season value.');
      return 10;
    }
    if (intent.isFlexibleDates &&
        _nearbyMonths(month).any(profile.bestMonths.contains)) {
      reasons.add('Nearby dates may offer better conditions.');
      return 9;
    }
    if (profile.badMonths.contains(month)) return -10;
    return 3;
  }

  double _durationScore(
    TimelineDestinationProfile profile,
    int? durationDays,
    List<String> reasons,
  ) {
    if (durationDays == null) return 0;
    if (durationDays >= profile.minDays && durationDays <= profile.maxDays) {
      reasons.add('Well matched to your trip length.');
      return 12;
    }
    if (durationDays <= 4 && profile.longHaulScore > 7) return -8;
    if (durationDays >= 9 && profile.longHaulScore > 7) {
      reasons.add('Worthwhile for a longer trip.');
      return 8;
    }
    return -3;
  }

  double _purposeScore(
    TimelineDestinationProfile profile,
    TravelPurpose purpose,
    List<String> reasons,
  ) {
    final strength = switch (purpose) {
      TravelPurpose.relaxation => profile.relaxationScore,
      TravelPurpose.romantic => profile.romanceScore,
      TravelPurpose.adventure => profile.natureScore,
      TravelPurpose.culture => profile.cultureScore,
      TravelPurpose.food => profile.foodScore,
      TravelPurpose.nightlife => profile.nightlifeScore,
      TravelPurpose.shopping => profile.shoppingScore,
      TravelPurpose.nature => profile.natureScore,
      TravelPurpose.familyFriendly => profile.safetyFamilyScore,
      TravelPurpose.workation => profile.workationScore,
    };
    if (profile.supportedPurposes.contains(purpose) || strength >= 8) {
      reasons.add(_purposeReason(purpose));
    }
    return strength * 2;
  }

  double _travelersScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    List<String> reasons,
  ) {
    if (intent.children > 0) {
      final familyScore = profile.safetyFamilyScore * 2;
      if (profile.safetyFamilyScore >= 8) {
        reasons.add('Family-friendly and comfortable for children.');
      }
      final nightlifePenalty = profile.nightlifeScore > 8 ? -8 : 0;
      return familyScore + nightlifePenalty;
    }

    if (intent.adults == 1 && profile.companionFit.contains('solo')) {
      reasons.add('Easy fit for a solo traveler.');
      return 10;
    }

    if (intent.adults == 2 && profile.romanceScore >= 8) {
      reasons.add('Great fit for a couple trip.');
      return 10;
    }

    if (intent.adults >= 3 && profile.nightlifeScore >= 8) {
      reasons.add('Strong fit for friends and nightlife.');
      return 9;
    }

    return 3;
  }

  double _budgetScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    List<String> reasons,
  ) {
    final origin = intent.origin.isEmpty ? 'DEFAULT' : intent.origin;
    final flightPrice = profile.estimatedFlightPriceByOrigin[origin] ??
        profile.estimatedFlightPriceByOrigin['DEFAULT'] ??
        700;
    final dailyCost = flightPrice / 5 + profile.estimatedHotelNightlyPrice;

    switch (intent.budgetPreference) {
      case BudgetType.budget:
        if (dailyCost <= 230 || profile.budgetLevel == BudgetType.budget) {
          reasons.add('Strong value for budget travelers.');
          return 14;
        }
        return -12;
      case BudgetType.midRange:
        if (dailyCost <= 360) {
          reasons.add('Strong value for mid-range travelers.');
          return 12;
        }
        return -4;
      case BudgetType.luxury:
        if (profile.budgetLevel == BudgetType.luxury ||
            profile.relaxationScore >= 8) {
          reasons.add('Premium stay and flight options fit well.');
          return 12;
        }
        return 2;
      case BudgetType.flexible:
        reasons.add('Balanced match across price and experience.');
        return 8;
    }
  }

  double _cabinScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    List<String> reasons,
  ) {
    switch (intent.cabinClass) {
      case CabinClass.economy:
        return profile.longHaulScore > 8 ? -3 : 3;
      case CabinClass.premiumEconomy:
        return profile.longHaulScore > 6 ? 5 : 2;
      case CabinClass.business:
      case CabinClass.first:
        if (profile.longHaulScore > 6) {
          reasons.add('Cabin preference suits the flight distance.');
          return 7;
        }
        return 2;
    }
  }

  double _originScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    List<String> reasons,
  ) {
    if (intent.originAirport == null) return -6;
    final origin = intent.originAirport!.iataCode;
    if (profile.directFlightAvailabilityMock &&
        profile.estimatedFlightPriceByOrigin.containsKey(origin)) {
      reasons.add('Good route fit from ${intent.originAirport!.iataCode}.');
      return 10;
    }
    return 2;
  }

  double _weatherCrowdScore(
    TimelineDestinationProfile profile,
    TravelIntent intent,
    int month,
    List<String> reasons,
  ) {
    final weather = profile.weatherScoreByMonth[month] ?? 6;
    final crowd = profile.crowdLevelByMonth[month] ?? 5;
    double score = weather * 1.4;
    if (weather >= 8) reasons.add('Weather looks favorable.');
    if (crowd >= 8 && !profile.bestMonths.contains(month)) {
      score -= intent.isFlexibleDates ? 3 : 7;
    }
    return score;
  }

  List<int> _nearbyMonths(int month) {
    final previous = month == 1 ? 12 : month - 1;
    final next = month == 12 ? 1 : month + 1;
    return [previous, next];
  }

  String _purposeReason(TravelPurpose purpose) {
    return switch (purpose) {
      TravelPurpose.relaxation => 'Great fit for a relaxation trip.',
      TravelPurpose.romantic => 'Scenic and romantic for two.',
      TravelPurpose.adventure => 'Strong outdoor and active-trip match.',
      TravelPurpose.culture => 'Rich culture, history, and architecture.',
      TravelPurpose.food => 'Strong food scene and local cuisine.',
      TravelPurpose.nightlife => 'Good nightlife and friends energy.',
      TravelPurpose.shopping => 'Great shopping and city variety.',
      TravelPurpose.nature => 'Strong nature and scenic escape.',
      TravelPurpose.familyFriendly => 'Family-friendly and easy to enjoy.',
      TravelPurpose.workation => 'Comfortable for a workation stay.',
    };
  }

  List<String> _shortReasons(List<String> reasons) {
    final deduped = <String>[];
    for (final reason in reasons) {
      if (!deduped.contains(reason)) deduped.add(reason);
      if (deduped.length == 3) break;
    }
    return deduped;
  }

  static final _profiles = [
    TimelineDestinationProfile(
      destination: Destination(
        id: 'paris',
        name: 'Paris',
        country: 'France',
        imageUrl:
            'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800',
        description: 'Culture, food, romance, and effortless city walks.',
        rating: 4.8,
      ),
      airportCode: 'CDG',
      bestMonths: [4, 5, 6, 9, 10],
      shoulderMonths: [3, 7, 8, 11],
      badMonths: [1, 2],
      minDays: 3,
      maxDays: 7,
      supportedPurposes: {
        TravelPurpose.romantic,
        TravelPurpose.culture,
        TravelPurpose.food,
        TravelPurpose.shopping,
        TravelPurpose.familyFriendly,
      },
      companionFit: {'solo', 'couple', 'family', 'friends'},
      budgetLevel: BudgetType.midRange,
      estimatedFlightPriceByOrigin: {
        'TLV': 360,
        'JFK': 520,
        'LHR': 180,
        'DEFAULT': 520,
      },
      estimatedHotelNightlyPrice: 190,
      weatherScoreByMonth: {
        1: 4,
        2: 4,
        3: 6,
        4: 8,
        5: 9,
        6: 9,
        7: 7,
        8: 7,
        9: 9,
        10: 8,
        11: 6,
        12: 5,
      },
      crowdLevelByMonth: {
        1: 4,
        2: 4,
        3: 5,
        4: 6,
        5: 7,
        6: 8,
        7: 9,
        8: 9,
        9: 7,
        10: 6,
        11: 5,
        12: 8,
      },
      safetyFamilyScore: 8,
      nightlifeScore: 8,
      cultureScore: 10,
      foodScore: 10,
      natureScore: 4,
      romanceScore: 10,
      relaxationScore: 7,
      shoppingScore: 9,
      workationScore: 8,
      longHaulScore: 4,
      directFlightAvailabilityMock: true,
    ),
    TimelineDestinationProfile(
      destination: Destination(
        id: 'maldives',
        name: 'Maldives',
        country: 'Maldives',
        imageUrl:
            'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?q=80&w=800',
        description: 'Resorts, calm water, and slow luxury days.',
        rating: 4.9,
      ),
      airportCode: 'MLE',
      bestMonths: [1, 2, 3, 12],
      shoulderMonths: [4, 11],
      badMonths: [6, 7, 8, 9],
      minDays: 6,
      maxDays: 12,
      supportedPurposes: {
        TravelPurpose.relaxation,
        TravelPurpose.romantic,
        TravelPurpose.nature,
      },
      companionFit: {'couple', 'family'},
      budgetLevel: BudgetType.luxury,
      estimatedFlightPriceByOrigin: {
        'TLV': 720,
        'JFK': 1150,
        'LHR': 850,
        'DEFAULT': 900,
      },
      estimatedHotelNightlyPrice: 420,
      weatherScoreByMonth: {
        1: 10,
        2: 10,
        3: 9,
        4: 8,
        5: 6,
        6: 4,
        7: 4,
        8: 4,
        9: 4,
        10: 6,
        11: 8,
        12: 10,
      },
      crowdLevelByMonth: {
        1: 8,
        2: 8,
        3: 7,
        4: 6,
        5: 4,
        6: 3,
        7: 3,
        8: 3,
        9: 3,
        10: 4,
        11: 6,
        12: 9,
      },
      safetyFamilyScore: 7,
      nightlifeScore: 3,
      cultureScore: 3,
      foodScore: 6,
      natureScore: 9,
      romanceScore: 10,
      relaxationScore: 10,
      shoppingScore: 2,
      workationScore: 6,
      longHaulScore: 8,
      directFlightAvailabilityMock: false,
    ),
    TimelineDestinationProfile(
      destination: Destination(
        id: 'tokyo',
        name: 'Tokyo',
        country: 'Japan',
        imageUrl:
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800',
        description: 'Food, design, culture, shopping, and high energy.',
        rating: 4.7,
      ),
      airportCode: 'HND',
      bestMonths: [3, 4, 5, 10, 11],
      shoulderMonths: [2, 6, 9, 12],
      badMonths: [7, 8],
      minDays: 7,
      maxDays: 14,
      supportedPurposes: {
        TravelPurpose.culture,
        TravelPurpose.food,
        TravelPurpose.shopping,
        TravelPurpose.nightlife,
        TravelPurpose.familyFriendly,
        TravelPurpose.workation,
      },
      companionFit: {'solo', 'couple', 'family', 'friends'},
      budgetLevel: BudgetType.midRange,
      estimatedFlightPriceByOrigin: {
        'TLV': 950,
        'JFK': 1050,
        'LHR': 980,
        'DEFAULT': 1000,
      },
      estimatedHotelNightlyPrice: 170,
      weatherScoreByMonth: {
        1: 6,
        2: 7,
        3: 9,
        4: 10,
        5: 9,
        6: 7,
        7: 5,
        8: 4,
        9: 7,
        10: 9,
        11: 9,
        12: 7,
      },
      crowdLevelByMonth: {
        1: 5,
        2: 5,
        3: 8,
        4: 10,
        5: 8,
        6: 6,
        7: 7,
        8: 8,
        9: 6,
        10: 7,
        11: 7,
        12: 8,
      },
      safetyFamilyScore: 9,
      nightlifeScore: 9,
      cultureScore: 10,
      foodScore: 10,
      natureScore: 6,
      romanceScore: 7,
      relaxationScore: 5,
      shoppingScore: 10,
      workationScore: 9,
      longHaulScore: 9,
      directFlightAvailabilityMock: true,
    ),
    TimelineDestinationProfile(
      destination: Destination(
        id: 'barcelona',
        name: 'Barcelona',
        country: 'Spain',
        imageUrl:
            'https://images.unsplash.com/photo-1523531294919-4bcd7c65e216?q=80&w=800',
        description: 'Beach, food, architecture, and social city energy.',
        rating: 4.7,
      ),
      airportCode: 'BCN',
      bestMonths: [5, 6, 9, 10],
      shoulderMonths: [3, 4, 7, 8, 11],
      badMonths: [1, 2],
      minDays: 3,
      maxDays: 8,
      supportedPurposes: {
        TravelPurpose.food,
        TravelPurpose.culture,
        TravelPurpose.nightlife,
        TravelPurpose.shopping,
        TravelPurpose.relaxation,
      },
      companionFit: {'solo', 'couple', 'friends', 'family'},
      budgetLevel: BudgetType.midRange,
      estimatedFlightPriceByOrigin: {
        'TLV': 310,
        'JFK': 650,
        'LHR': 160,
        'DEFAULT': 560,
      },
      estimatedHotelNightlyPrice: 150,
      weatherScoreByMonth: {
        1: 5,
        2: 5,
        3: 7,
        4: 8,
        5: 9,
        6: 10,
        7: 8,
        8: 8,
        9: 10,
        10: 9,
        11: 7,
        12: 5,
      },
      crowdLevelByMonth: {
        1: 4,
        2: 4,
        3: 5,
        4: 6,
        5: 7,
        6: 8,
        7: 10,
        8: 10,
        9: 8,
        10: 6,
        11: 5,
        12: 5,
      },
      safetyFamilyScore: 7,
      nightlifeScore: 9,
      cultureScore: 9,
      foodScore: 9,
      natureScore: 5,
      romanceScore: 8,
      relaxationScore: 7,
      shoppingScore: 8,
      workationScore: 8,
      longHaulScore: 4,
      directFlightAvailabilityMock: true,
    ),
    TimelineDestinationProfile(
      destination: Destination(
        id: 'london',
        name: 'London',
        country: 'United Kingdom',
        imageUrl:
            'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=800',
        description:
            'Museums, theater, shopping, parks, and workation comfort.',
        rating: 4.6,
      ),
      airportCode: 'LHR',
      bestMonths: [5, 6, 9],
      shoulderMonths: [4, 7, 8, 10, 12],
      badMonths: [1, 2],
      minDays: 3,
      maxDays: 7,
      supportedPurposes: {
        TravelPurpose.culture,
        TravelPurpose.shopping,
        TravelPurpose.familyFriendly,
        TravelPurpose.workation,
        TravelPurpose.food,
      },
      companionFit: {'solo', 'couple', 'family', 'friends'},
      budgetLevel: BudgetType.midRange,
      estimatedFlightPriceByOrigin: {
        'TLV': 430,
        'JFK': 560,
        'CDG': 140,
        'DEFAULT': 520,
      },
      estimatedHotelNightlyPrice: 210,
      weatherScoreByMonth: {
        1: 4,
        2: 4,
        3: 5,
        4: 7,
        5: 8,
        6: 9,
        7: 7,
        8: 7,
        9: 8,
        10: 6,
        11: 5,
        12: 6,
      },
      crowdLevelByMonth: {
        1: 4,
        2: 4,
        3: 5,
        4: 6,
        5: 7,
        6: 8,
        7: 9,
        8: 9,
        9: 7,
        10: 6,
        11: 5,
        12: 8,
      },
      safetyFamilyScore: 9,
      nightlifeScore: 8,
      cultureScore: 10,
      foodScore: 8,
      natureScore: 5,
      romanceScore: 7,
      relaxationScore: 5,
      shoppingScore: 10,
      workationScore: 10,
      longHaulScore: 5,
      directFlightAvailabilityMock: true,
    ),
  ];
}
