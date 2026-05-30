import 'dart:async';
import 'dart:math';
import '../../models/timeline_models.dart';

class FlightInsightsService {
  /// Fetches flight pricing insights for a specific destination and month.
  /// In a production environment, this would hit Skyscanner or Amadeus REST APIs.
  Future<FlightData> fetchFlightInsights({
    required String destinationName,
    required String originCity, // Assuming we have an origin, e.g., 'NYC'
    required int month,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock pricing based on destination length/hash to keep it somewhat deterministic
    final random = Random(destinationName.hashCode + month);
    final basePrice = 300.0 + random.nextDouble() * 800.0;
    
    // Determine trend
    final trends = ['up', 'down', 'stable'];
    final trend = trends[random.nextInt(trends.length)];

    return FlightData(
      averagePrice: basePrice,
      currency: 'USD',
      trend: trend,
      popularAirlines: ['Air France', 'Delta', 'Emirates', 'Lufthansa'].sublist(0, 1 + random.nextInt(3)),
      bestTimeToBook: random.nextBool() ? 'Book within 12 days' : null,
      directFlightCount: 1 + random.nextInt(3),
    );
  }
}
