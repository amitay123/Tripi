import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/settings_model.dart';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';
import '../utils/offline_settings_queue.dart';

/// Keys for user-scoped SharedPreferences entries.
/// Only these keys are removed on logout — device-level prefs are preserved.
abstract class _UserScopedPrefKeys {
  static const settings = 'user_settings_cache';
  static const settingsUpdatedAt = 'user_settings_updated_at';
  static const avatarUrl = 'user_avatar_url';
  // Other user-scoped keys can be added here.
}

class SettingsProvider extends ChangeNotifier {
  final AnalyticsService _analytics;
  final OfflineSettingsQueue _offlineQueue;

  SettingsModel _settings = const SettingsModel();
  bool _isLoading = false;
  bool _isLoadingAvatar = false;
  String? _error;
  String? _userId;

  // Optimistic in-flight update marker
  bool _isSyncing = false;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isLoadingAvatar => _isLoadingAvatar;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  ThemeMode get themeMode => _settings.themeMode;
  Locale get locale => _settings.locale;

  SettingsProvider({
    AnalyticsService? analytics,
    OfflineSettingsQueue? offlineQueue,
  })  : _analytics = analytics ?? LocalAnalyticsService(),
        _offlineQueue = offlineQueue ?? OfflineSettingsQueue();

  // ---------------------------------------------------------------------------
  // Load: cache-first, then background Supabase sync
  // ---------------------------------------------------------------------------

  Future<void> load(String userId) async {
    _userId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Step 1: Load from local cache immediately
    await _loadFromCache();
    _isLoading = false;
    notifyListeners();

    // Step 2: Background sync from Supabase
    _syncFromRemote();

    // Step 3: Flush any offline-queued changes
    _flushOfflineQueue();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_UserScopedPrefKeys.settings);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _settings = SettingsModel.fromJson(json);
      }
    } catch (e) {
      debugPrint('[SettingsProvider] Cache load error: $e');
    }
  }

  Future<void> _syncFromRemote() async {
    if (_userId == null) return;
    try {
      final remote = await SupabaseService.fetchSettings(_userId!);
      if (remote == null) {
        // First time — create defaults on server
        await SupabaseService.upsertSettings(_userId!, _settings.toJson());
        return;
      }

      final remoteSettings = SettingsModel.fromJson(remote);

      // Conflict resolution: newest updated_at wins
      if (remoteSettings.updatedAt.isAfter(_settings.updatedAt)) {
        _settings = remoteSettings;
        await _writeCache(_settings);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SettingsProvider] Remote sync error: $e');
    }
  }

  Future<void> _flushOfflineQueue() async {
    if (!await _offlineQueue.hasItems()) return;
    if (_userId == null) return;

    try {
      final queued = await _offlineQueue.peek();
      if (queued == null) return;

      // Only apply if still newer than current
      if (queued.updatedAt.isAfter(_settings.updatedAt)) {
        await SupabaseService.upsertSettings(_userId!, queued.toJson());
        _settings = queued;
        await _writeCache(_settings);
        notifyListeners();
      }
      await _offlineQueue.clear();
      debugPrint('[SettingsProvider] Offline queue flushed');
    } catch (e) {
      debugPrint('[SettingsProvider] Offline flush error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Update: optimistic local write → async remote sync
  // ---------------------------------------------------------------------------

  Future<void> update(SettingsModel updated) async {
    final stamped = updated.copyWith(updatedAt: DateTime.now());

    // Optimistic update — apply locally immediately
    _settings = stamped;
    await _writeCache(_settings);
    notifyListeners();

    // Async remote sync
    if (_userId != null) {
      _isSyncing = true;
      try {
        await SupabaseService.upsertSettings(_userId!, _settings.toJson());
      } catch (e) {
        debugPrint('[SettingsProvider] Remote update failed, queuing: $e');
        await _offlineQueue.enqueue(_settings);
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  // Convenience shortcut for single-field updates
  Future<void> updateField(SettingsModel Function(SettingsModel) fn,
      {String? analyticsEvent,
      Map<String, dynamic>? analyticsParams}) async {
    await update(fn(_settings));
    if (analyticsEvent != null) {
      await _analytics.logEvent(analyticsEvent, parameters: analyticsParams);
    }
  }

  // ---------------------------------------------------------------------------
  // Avatar Upload
  // ---------------------------------------------------------------------------

  Future<String?> pickAndUploadAvatar(ImageSource source) async {
    if (_userId == null) return null;
    _isLoadingAvatar = true;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return null;

      List<int> bytes;

      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      } else {
        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: 400,
          minHeight: 400,
          quality: 80,
          format: CompressFormat.jpeg,
        );
        if (compressed == null) return null;
        bytes = compressed;
      }

      final url = await SupabaseService.uploadAvatar(_userId!, bytes);

      // Update profile avatar_url with cache-busting URL
      await SupabaseService.updateProfile(_userId!, {'avatar_url': url});

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_UserScopedPrefKeys.avatarUrl, url);

      await _analytics.logEvent(SettingsAnalyticsEvents.avatarChanged);
      return url;
    } catch (e) {
      _error = 'Failed to upload avatar. Please try again.';
      debugPrint('[SettingsProvider] Avatar upload error: $e');
      return null;
    } finally {
      _isLoadingAvatar = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Logout — selective SharedPreferences clear (user-scoped only)
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      debugPrint('[SettingsProvider] signOut error: $e');
    }

    // Clear ONLY user-scoped keys, preserving device/app-level prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_UserScopedPrefKeys.settings);
    await prefs.remove(_UserScopedPrefKeys.settingsUpdatedAt);
    await prefs.remove(_UserScopedPrefKeys.avatarUrl);
    // Also clear user-specific keys from other providers:
    await prefs.remove('auth_intent');
    await prefs.remove('cached_trips');
    await prefs.remove('ai_session_state');
    await prefs.remove('user_ai_preferences');

    await _analytics.logEvent(SettingsAnalyticsEvents.logoutTriggered);

    // Reset in-memory state
    _settings = const SettingsModel();
    _userId = null;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Immutable snapshot for AI engine (locked at call time)
  // ---------------------------------------------------------------------------

  SettingsSnapshot getSnapshot() => _settings.toSnapshot();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _writeCache(SettingsModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _UserScopedPrefKeys.settings, jsonEncode(model.toJson()));
    } catch (e) {
      debugPrint('[SettingsProvider] Cache write error: $e');
    }
  }
}
