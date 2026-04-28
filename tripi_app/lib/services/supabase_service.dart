import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as models;

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // --- AUTH METHODS ---

  /// Sign up a new user with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  static Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  /// Get current session
  static Session? get currentSession => _client.auth.currentSession;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  // --- TRIP METHODS ---

  /// Fetch all trips for the current authenticated user
  static Future<List<models.Trip>> getTrips() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('trips')
        .select()
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null) // Only fetch non-deleted trips
        .order('created_at', ascending: false);

    if ((response as List).isNotEmpty) {
      debugPrint(
          '***** Supabase trips table columns: ${(response.first as Map).keys}');
    }

    return (response as List)
        .map((json) => models.Trip.fromJson(json))
        .toList();
  }

  /// Soft deletes a trip by setting deleted_at
  static Future<void> deleteTrip(String tripId) async {
    await _client
        .from('trips')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', tripId);
  }

  /// Create or update a trip
  static Future<models.Trip> createTrip(models.Trip trip) async {
    final json = trip.toJson();
    
    // For upsert, if id exists and is not a temporary one, keep it.
    // Otherwise remove it to let DB generate a new UUID.
    if (trip.id.isEmpty || trip.id.startsWith('t')) {
      json.remove('id');
    } else {
      json['id'] = trip.id;
    }

    debugPrint('***** SupabaseService: Attempting to upsert trip with payload: $json');

    try {
      final response = await _client.from('trips').upsert(json).select();

      if (response == null || (response as List).isEmpty) {
        debugPrint(
            '***** SupabaseService: Upsert appeared to succeed but no data was returned. Check RLS policies.');
        throw Exception(
            'Failed to retrieve saved trip. This might be due to Row Level Security (RLS) policies.');
      }

      final savedData = (response as List).first;
      debugPrint('***** SupabaseService: Trip upserted successfully: $savedData');
      
      try {
        return models.Trip.fromJson(savedData);
      } catch (parseErr) {
        debugPrint('***** SupabaseService: fromJson failed ($parseErr), returning original with DB id');
        return trip.copyWith(
          id: savedData['id']?.toString() ?? '',
          updatedAt: DateTime.now(),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint(
          '***** SupabaseService PostgrestException: code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}');
      
      if (e.code == '42P01') {
        throw Exception('The "trips" table does not exist in the database.');
      } else if (e.code == '23503') {
        throw Exception('User ID reference failure. Please ensure you are correctly logged in.');
      } else if (e.code == '42703') {
        debugPrint('***** SCHEMA MISMATCH: ${e.message}');
        throw Exception('Database schema mismatch: The column "budget_total" is missing. Please run the SQL migration in your Supabase dashboard.');
      }
      
      rethrow;
    } catch (e) {
      debugPrint('***** SupabaseService ERROR (${e.runtimeType}): $e');
      rethrow;
    }
  }

  /// Update an existing trip
  static Future<void> updateTrip(models.Trip trip) async {
    await _client.from('trips').update(trip.toJson()).eq('id', trip.id);
  }

  /// Hard delete a trip (use with caution)
  static Future<void> hardDeleteTrip(String tripId) async {
    await _client.from('trips').delete().eq('id', tripId);
  }
}
