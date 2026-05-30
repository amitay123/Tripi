import 'dart:async';
import 'dart:math';
import '../../models/timeline_models.dart';

class HotelInsightsService {
  /// Fetches hotel pricing and availability insights for a destination and month.
  /// In production, this would hit Booking.com or Agoda REST APIs.
  Future<HotelData> fetchHotelInsights({
    required String destinationName,
    required int month,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random(destinationName.hashCode + month + 1);
    final nightlyRate = 80.0 + random.nextDouble() * 300.0;
    
    final availability = 40 + random.nextInt(60); // 40-100%
    
    final trends = ['low', 'moderate', 'high'];
    final trend = trends[random.nextInt(trends.length)];

    return HotelData(
      averageNightlyRate: nightlyRate,
      currency: 'USD',
      availabilityScore: availability,
      bookingTrend: trend,
      bestNeighborhoods: ['Downtown', 'Old Town', 'Beachfront', 'Arts District'].sublist(0, 1 + random.nextInt(2)),
    );
  }
}
