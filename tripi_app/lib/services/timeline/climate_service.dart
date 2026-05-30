import 'dart:async';
import 'dart:math';
import '../../models/timeline_models.dart';

class ClimateService {
  /// Fetches historical weather data for a destination and month.
  /// In production, this would hit Weather APIs like OpenWeatherMap or Tomorrow.io.
  Future<WeatherData> fetchClimateInsights({
    required String destinationName,
    required int month,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 400));

    final random = Random(destinationName.hashCode + month + 2);
    
    // Simulate seasonal variation
    // In northern hemisphere, July (7) is hot. Let's make a simple curve.
    final tempBase = 15.0 - 10.0 * cos((month - 1) * pi / 6.0);
    final high = tempBase + 5.0 + random.nextDouble() * 10.0;
    final low = tempBase - 5.0 - random.nextDouble() * 5.0;

    final conditions = ['sunny', 'cloudy', 'rainy', 'partly cloudy'];
    final condition = conditions[random.nextInt(conditions.length)];
    
    final rainfall = random.nextInt(15); // 0 to 14 days of rain

    return WeatherData(
      averageHigh: high,
      averageLow: low,
      condition: condition,
      rainfallDays: rainfall,
    );
  }
}
