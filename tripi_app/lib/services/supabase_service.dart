import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://fbtoyhnjwyhssozetfhw.supabase.co';
  static const String _anonKey = 'sb_publishable_DWgDyHuCNZLMHIbIkVuCkA_eTe_Z4Vw';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://tripi-app-af1ad.web.app/#/set-new-password',
    );
  }

  static Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  static User? get currentUser => client.auth.currentUser;
}
