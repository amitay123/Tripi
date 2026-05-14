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

  /// Sign in with Google OAuth
  /// [intent] should be 'login' or 'register'
  static Future<void> signInWithGoogle({required String intent}) async {
    final String baseRedirect = kIsWeb
        ? (Uri.base.origin.endsWith('/')
            ? Uri.base.origin
            : '${Uri.base.origin}/')
        : 'io.supabase.tripi://login-callback';

    // Embed intent in the redirect URL so it survives the OAuth page redirect
    final String redirectTo = kIsWeb
        ? Uri.parse(baseRedirect)
            .replace(queryParameters: {'intent': intent}).toString()
        : baseRedirect;

    debugPrint(
        'Social Auth Google: Redirecting to $redirectTo (intent=$intent)');

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  /// Sign in with Facebook OAuth
  /// [intent] should be 'login' or 'register'
  static Future<void> signInWithFacebook({required String intent}) async {
    final String baseRedirect = kIsWeb
        ? (Uri.base.origin.endsWith('/')
            ? Uri.base.origin
            : '${Uri.base.origin}/')
        : 'io.supabase.tripi://login-callback';

    final String redirectTo = kIsWeb
        ? Uri.parse(baseRedirect)
            .replace(queryParameters: {'intent': intent}).toString()
        : baseRedirect;

    debugPrint(
        'Social Auth Facebook: Redirecting to $redirectTo (intent=$intent)');

    await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: redirectTo,
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
  static models.User? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return models.User(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name']?.toString() ?? 'Traveler',
      profileImage: user.userMetadata?['avatar_url']?.toString(),
      providerType: user.appMetadata['provider']?.toString(),
    );
  }

  /// Check if a user with the given email is registered
  static Future<bool> isUserRegistered(String email) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return response != null;
  }

  /// Create a profile in the public.profiles table
  static Future<void> createProfile({
    required String id,
    required String email,
    required String name,
  }) async {
    await _client.from('profiles').upsert({
      'id': id,
      'email': email,
      'full_name': name,
    });
  }

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
    await _client.from('trips').update(
        {'deleted_at': DateTime.now().toIso8601String()}).eq('id', tripId);
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

    debugPrint(
        '***** SupabaseService: Attempting to upsert trip with payload: $json');

    try {
      final response = await _client.from('trips').upsert(json).select();

      if ((response as List).isEmpty) {
        debugPrint(
            '***** SupabaseService: Upsert appeared to succeed but no data was returned. Check RLS policies.');
        throw Exception(
            'Failed to retrieve saved trip. This might be due to Row Level Security (RLS) policies.');
      }

      final savedData = (response as List).first;
      debugPrint(
          '***** SupabaseService: Trip upserted successfully: $savedData');

      try {
        return models.Trip.fromJson(savedData);
      } catch (parseErr) {
        debugPrint(
            '***** SupabaseService: fromJson failed ($parseErr), returning original with DB id');
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
        throw Exception(
            'User ID reference failure. Please ensure you are correctly logged in.');
      } else if (e.code == '42703') {
        debugPrint('***** SCHEMA MISMATCH: ${e.message}');
        throw Exception(
            'Database schema mismatch: The column "budget_total" is missing. Please run the SQL migration in your Supabase dashboard.');
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

  // --- PROFILE METHODS ---

  /// Fetch extended profile data for the current user.
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[SupabaseService] getProfile error: $e');
      return null;
    }
  }

  /// Update profile fields (partial update — only provided fields).
  static Future<void> updateProfile(
      String userId, Map<String, dynamic> fields) async {
    try {
      await _client.from('profiles').update(fields).eq('id', userId);
    } catch (e) {
      debugPrint('[SupabaseService] updateProfile error: $e');
      rethrow;
    }
  }

  // Reserved usernames that cannot be registered
  static const _reservedUsernames = {
    'admin', 'support', 'system', 'tripi', 'help', 'info',
    'contact', 'root', 'superuser', 'bot', 'official', 'staff',
  };

  /// Checks if a username is available and valid.
  /// Returns null if valid, or an error string.
  static Future<String?> checkUsernameAvailable(
      String username, String currentUserId) async {
    final normalized = username.toLowerCase().trim();

    // Format validation
    if (normalized.length < 3 || normalized.length > 20) {
      return 'Username must be between 3 and 20 characters.';
    }
    if (normalized.contains(' ')) {
      return 'Username cannot contain spaces.';
    }
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(normalized)) {
      return 'Only lowercase letters, numbers, dots, and underscores.';
    }
    if (_reservedUsernames.contains(normalized)) {
      return 'This username is not available.';
    }

    // Uniqueness check
    try {
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('username', normalized)
          .neq('id', currentUserId)
          .maybeSingle();
      if (result != null) return 'This username is already taken.';
      return null; // Available
    } catch (e) {
      debugPrint('[SupabaseService] checkUsername error: $e');
      return null; // Fail open — validate server-side on save
    }
  }

  // --- SETTINGS METHODS ---

  /// Fetch user settings from Supabase.
  static Future<Map<String, dynamic>?> fetchSettings(String userId) async {
    try {
      return await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[SupabaseService] fetchSettings error: $e');
      return null;
    }
  }

  /// Upsert user settings to Supabase.
  static Future<void> upsertSettings(
      String userId, Map<String, dynamic> settingsJson) async {
    try {
      await _client.from('user_settings').upsert({
        'user_id': userId,
        ...settingsJson,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] upsertSettings error: $e');
      rethrow;
    }
  }

  // --- AVATAR METHODS ---

  /// Uploads avatar bytes to Supabase Storage at avatars/{userId}/profile.jpg
  /// Returns the public CDN URL with a cache-busting query param.
  static Future<String> uploadAvatar(
      String userId, List<int> compressedBytes) async {
    final path = 'avatars/$userId/profile.jpg';

    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(compressedBytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true, // Overwrite existing
          ),
        );

    final baseUrl =
        _client.storage.from('avatars').getPublicUrl(path);

    // Cache busting: append timestamp so stale CDN images are replaced
    final cacheBusted =
        '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    return cacheBusted;
  }

  // --- SECURITY EVENTS ---

  /// Logs a security event for auditing purposes.
  /// event_type examples: 'password_reset', 'email_change', '2fa_enabled'
  static Future<void> logSecurityEvent(
      String userId, String eventType,
      {Map<String, dynamic>? metadata}) async {
    try {
      await _client.from('security_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'metadata': metadata ?? {},
      });
      debugPrint('[Security] Logged event: $eventType for user $userId');
    } catch (e) {
      debugPrint('[SupabaseService] logSecurityEvent error: $e');
    }
  }
}

