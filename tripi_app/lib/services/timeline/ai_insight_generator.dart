import 'dart:async';
import '../../models/timeline_models.dart';

class AiInsightGenerator {
  /// Generates a personalized insight string explaining why the destination is a good fit.
  /// In production, this would call a Supabase Edge Function which securely interacts with an LLM.
  Future<String> generateInsight({
    required String destinationName,
    required FlightData flightData,
    required HotelData hotelData,
    required WeatherData weatherData,
    required Map<String, dynamic> userPreferences,
  }) async {
    // Simulate API latency
    await Future.delayed(const Duration(milliseconds: 800));

    // Basic logic to simulate AI context awareness
    final isBudgetFriendly = flightData.averagePrice < 500 && hotelData.averageNightlyRate < 150;
    final isWarm = weatherData.averageHigh > 22.0;
    
    final StringBuffer insight = StringBuffer();
    insight.write('$destinationName is an excellent choice right now. ');

    if (isBudgetFriendly) {
      insight.write('It\'s currently highly affordable with flights averaging \$${flightData.averagePrice.toStringAsFixed(0)}. ');
    } else {
      insight.write('While premium, it offers incredible luxury experiences. ');
    }

    if (isWarm) {
      insight.write('You can expect warm, beautiful ${weatherData.condition} weather, perfect for outdoor activities. ');
    } else {
      insight.write('The cooler ${weatherData.condition} weather makes it perfect for cozy indoor experiences and exploring museums. ');
    }

    return insight.toString();
  }
}
