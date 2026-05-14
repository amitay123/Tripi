import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract analytics interface — vendor-agnostic.
/// Concrete implementations (Firebase, Mixpanel, custom) implement this.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> setUserProperty(String name, String? value);
}

/// Event name constants for settings-related analytics.
abstract class SettingsAnalyticsEvents {
  static const String intensityChanged = 'settings_intensity_changed';
  static const String tripStyleSelected = 'settings_trip_style_selected';
  static const String tripStyleDeselected = 'settings_trip_style_deselected';
  static const String languageChanged = 'settings_language_changed';
  static const String darkModeChanged = 'settings_dark_mode_changed';
  static const String pushToggled = 'settings_push_notification_toggled';
  static const String emailToggled = 'settings_email_notification_toggled';
  static const String avatarChanged = 'settings_avatar_changed';
  static const String logoutTriggered = 'settings_logout_triggered';
  static const String travelerDefaultsChanged = 'settings_traveler_defaults_changed';
}

/// Local, anonymous analytics queue.
/// Queues events in SharedPreferences for future backend flush.
/// NO PII is stored — only aggregate behavioral data.
class LocalAnalyticsService implements AnalyticsService {
  static const _queueKey = 'analytics_event_queue';
  static const _maxQueueSize = 500;

  @override
  Future<void> logEvent(String name,
      {Map<String, dynamic>? parameters}) async {
    try {
      final event = {
        'name': name,
        'ts': DateTime.now().millisecondsSinceEpoch,
        if (parameters != null) 'params': parameters,
      };
      await _enqueue(event);
      debugPrint('[Analytics] $name: $parameters');
    } catch (e) {
      debugPrint('[Analytics] log error: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    // No-op for local implementation; real impl sets user properties.
    debugPrint('[Analytics] setUserProperty $name=$value');
  }

  Future<void> _enqueue(Map<String, dynamic> event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final List<dynamic> queue = raw != null ? jsonDecode(raw) as List : [];
    queue.add(event);
    if (queue.length > _maxQueueSize) queue.removeAt(0);
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Returns pending events (for future flush to backend).
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}
