import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../models/timeline_models.dart';
import 'flight_insights_service.dart';
import 'hotel_insights_service.dart';
import 'climate_service.dart';
import 'ai_insight_generator.dart';

class TimelineOrchestratorService {
  final SupabaseClient _client = Supabase.instance.client;
  
  final FlightInsightsService _flightService = FlightInsightsService();
  final HotelInsightsService _hotelService = HotelInsightsService();
  final ClimateService _climateService = ClimateService();
  final AiInsightGenerator _aiService = AiInsightGenerator();

  // In-memory cache to prevent repeated lookups in the same session
  final Map<String, DestinationInsight> _memoryCache = {};

  /// Gets insights for a specific destination and month.
  /// First checks memory cache, then Supabase DB cache, and finally triggers parallel API fetches if stale/missing.
  Future<DestinationInsight?> getInsights({
    required Destination destination,
    required int month,
    String originCity = 'TLV',
  }) async {
    final cacheKey = '${destination.id}_$month';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      // Simple TTL check for memory cache (e.g., 1 hour)
      if (DateTime.now().difference(cached.updatedAt).inHours < 1) {
        return cached;
      }
    }

    // 2. Check Supabase 'destination_insights' table
    try {
      final response = await _client
          .from('destination_insights')
          .select()
          .eq('destination_name', destination.name)
          .eq('month', month)
          .maybeSingle();

      if (response != null) {
        final updatedAt = DateTime.parse(response['updated_at'].toString());
        // If the DB cache is fresh enough (e.g., within 24 hours), use it
        if (DateTime.now().difference(updatedAt).inHours < 24) {
          final insight = DestinationInsight.fromJson(response, destination);
          _memoryCache[cacheKey] = insight;
          return insight;
        }
      }
    } catch (e) {
      debugPrint('[TimelineOrchestrator] Supabase cache lookup failed: $e');
      // Continue to fetch fresh data if DB cache fails
    }

    // 3. Fetch fresh data in parallel
    try {

      final results = await Future.wait([
        _flightService.fetchFlightInsights(
          destinationName: destination.name, originCity: originCity, month: month),
        _hotelService.fetchHotelInsights(
          destinationName: destination.name, month: month),
        _climateService.fetchClimateInsights(
          destinationName: destination.name, month: month),
      ]);

      final flightData = results[0] as FlightData;
      final hotelData = results[1] as HotelData;
      final weatherData = results[2] as WeatherData;

      // TODO: Fetch real user preferences from Supabase `user_ai_preferences`
      final userPreferences = <String, dynamic>{
        'budget_tendencies': 'moderate',
      };

      // 4. Generate AI Insight
      final aiInsight = await _aiService.generateInsight(
        destinationName: destination.name,
        flightData: flightData,
        hotelData: hotelData,
        weatherData: weatherData,
        userPreferences: userPreferences,
      );

      final newInsight = DestinationInsight(
        id: '', // Supabase will generate UUID
        destination: destination,
        month: month,
        flightData: flightData,
        hotelData: hotelData,
        weatherData: weatherData,
        aiInsight: aiInsight,
        popularity: 'high',
        crowdLevels: 'moderate',
        updatedAt: DateTime.now(),
      );

      // 5. Store in Supabase cache asynchronously (fire and forget)
      _cacheInSupabase(newInsight);

      // Store in memory cache
      _memoryCache[cacheKey] = newInsight;

      return newInsight;
    } catch (e) {
      debugPrint('[TimelineOrchestrator] API fetching failed: $e');
      return null;
    }
  }

  Future<void> _cacheInSupabase(DestinationInsight insight) async {
    try {
      final payload = insight.toJson();
      payload.remove('id'); // Let DB handle ID

      // Use upsert matching destination_name and month
      await _client.from('destination_insights').upsert(
        payload,
        onConflict: 'destination_name, month',
      );
    } catch (e) {
      debugPrint('[TimelineOrchestrator] Failed to cache in Supabase: $e');
    }
  }
}
