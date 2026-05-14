import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

/// Queues settings changes made while offline and syncs them when online.
/// Uses SharedPreferences as the persistence layer for the queue.
class OfflineSettingsQueue {
  static const _queueKey = 'offline_settings_queue';

  /// Enqueues a settings update to be synced when connectivity returns.
  Future<void> enqueue(SettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final item = {
        'settings': settings.toJson(),
        'queued_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_queueKey, jsonEncode(item));
      debugPrint('[OfflineQueue] Settings queued for sync');
    } catch (e) {
      debugPrint('[OfflineQueue] Enqueue error: $e');
    }
  }

  /// Returns the queued settings update, if any.
  Future<SettingsModel?> peek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null) return null;
      final Map<String, dynamic> item = jsonDecode(raw);
      return SettingsModel.fromJson(
          item['settings'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[OfflineQueue] Peek error: $e');
      return null;
    }
  }

  /// Clears the queue after successful sync.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    debugPrint('[OfflineQueue] Queue cleared after sync');
  }

  Future<bool> hasItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_queueKey);
  }
}
