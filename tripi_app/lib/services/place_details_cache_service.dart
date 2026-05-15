import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_result.dart';

class PlaceDetailsCacheService {
  static const int _ttlHours = 12;
  static const String _keyPrefix = 'place_details_cache_';
  static const String _tsSuffix = '_ts';

  static Future<PlaceResult?> get(String placeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$placeId';
      final cached = prefs.getString(key);
      final tsStr = prefs.getString('$key$_tsSuffix');
      if (cached == null || tsStr == null) return null;
      final cachedAt = DateTime.tryParse(tsStr);
      if (cachedAt == null) return null;
      if (DateTime.now().difference(cachedAt).inHours >= _ttlHours) {
        await prefs.remove(key);
        await prefs.remove('$key$_tsSuffix');
        return null;
      }
      final map = jsonDecode(cached) as Map<String, dynamic>;
      return PlaceResult.fromMap(map);
    } catch (e) {
      debugPrint('PlaceDetailsCacheService.get error: $e');
      return null;
    }
  }

  static Future<void> set(String placeId, PlaceResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$placeId';
      final map = {
        'place_id': result.placeId,
        'name': result.name,
        'lat': result.lat,
        'lng': result.lng,
        'formatted_address': result.formattedAddress,
        'rating': result.rating,
        'user_ratings_total': result.userRatingsTotal,
        'types': result.types,
        'price_level': result.priceLevel,
        'photo_references': result.photoReferences,
        'image_url': result.imageUrl,
        'source': result.source.name,
        'website': result.website,
        'opening_hours': result.openingHours,
        'description': result.description,
        'country_code': result.countryCode,
      };
      await prefs.setString(key, jsonEncode(map));
      await prefs.setString('$key$_tsSuffix', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('PlaceDetailsCacheService.set error: $e');
    }
  }

  static Future<void> evict(String placeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$placeId';
      await prefs.remove(key);
      await prefs.remove('$key$_tsSuffix');
    } catch (e) {
      debugPrint('PlaceDetailsCacheService.evict error: $e');
    }
  }
}
