import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/timeline_models.dart';

class TravelContextService {
  static const _table = 'user_travel_context';
  final SupabaseClient _client;

  TravelContextService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<TravelIntent?> load() async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final json = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (json == null) return null;
      return TravelIntent.fromTravelContextJson(
        Map<String, dynamic>.from(json),
      );
    } catch (e) {
      debugPrint('[TravelContextService] load failed: $e');
      return null;
    }
  }

  Future<void> save(
    TravelIntent intent, {
    bool clearOrigin = false,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final payload = intent.normalized().toTravelContextJson(userId);
      if (intent.originAirport == null && !clearOrigin) {
        payload.remove('origin_airport_iata');
        payload.remove('origin_airport_name');
        payload.remove('origin_city');
        payload.remove('origin_country');
      }
      await _client.from(_table).upsert(
            payload,
            onConflict: 'user_id',
          );
    } catch (e) {
      debugPrint('[TravelContextService] save failed: $e');
    }
  }
}
