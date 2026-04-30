import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class PlacesService {
  // Singleton pattern
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _parseAutocompleteResponse(dynamic data) {
    try {
      final Map<String, dynamic> json = data is String ? jsonDecode(data) : data;
      return List<Map<String, dynamic>>.from(json['predictions'] ?? []);
    } catch (e) {
      debugPrint('Error parsing autocomplete response: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> autocompletePlaces(String input,
      {String? countryCode, double? lat, double? lng}) async {
    try {
      final Map<String, String> params = {'input': input};
      if (countryCode != null && countryCode.isNotEmpty) {
        params['components'] = 'country:$countryCode';
      }
      if (lat != null && lng != null) {
        params['location'] = '$lat,$lng';
        params['radius'] = '50000';
      }

      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {'endpoint': 'autocomplete', 'params': params},
      );

      if (response.status == 200) {
        return _parseAutocompleteResponse(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> autocompleteCountries(String input) async {
    try {
      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {
          'endpoint': 'autocomplete',
          'params': {'input': input, 'types': 'country'}
        },
      );

      if (response.status == 200) {
        return _parseAutocompleteResponse(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Autocomplete countries error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> autocompleteCities(
      String input, String? countryCode) async {
    try {
      final Map<String, String> params = {
        'input': input,
      };
      if (countryCode != null && countryCode.isNotEmpty) {
        params['components'] = 'country:$countryCode';
      }

      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {'endpoint': 'autocomplete', 'params': params},
      );

      if (response.status == 200) {
        return _parseAutocompleteResponse(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Autocomplete cities error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {
          'endpoint': 'details',
          'params': {
            'place_id': placeId,
            'fields':
                'name,formatted_address,geometry,photos,types,address_components,rating,opening_hours,website,price_level,editorial_summary'
          }
        },
      );

      if (response.status == 200) {
        final Map<String, dynamic> data = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        final result = data['result'];
        if (result != null) {
          return {
            'name': result['name'],
            'formatted_address': result['formatted_address'],
            'lat': result['geometry']['location']['lat'],
            'lng': result['geometry']['location']['lng'],
            'photo_references': (result['photos'] != null)
                ? List<String>.from(result['photos']
                    .map((p) => p['photo_reference']?.toString())
                    .where((p) => p != null))
                : [],
            'rating': result['rating'],
            'opening_hours': result['opening_hours'],
            'website': result['website'],
            'price_level': result['price_level'],
            'description': result['editorial_summary']?['overview'],
            'types': result['types'] != null
                ? List<String>.from(result['types'])
                : [],
            'country_code': _extractCountryCode(result['address_components']),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Place details error: $e');
      return null;
    }
  }

  String? getPhotoUrl(String? photoReference) {
    if (photoReference == null) return null;
    const String apiKey = 'AIzaSyDNxKWoy8qIDOMyO8FTf1DED_wByeKzm2M';
    final String url =
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$photoReference&key=$apiKey';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
  }

  Future<Map<String, dynamic>?> getDistanceAndDuration(
      double lat1, double lng1, double lat2, double lng2, String mode) async {
    try {
      final String gMode = mode == 'flight' ? 'driving' : mode.toLowerCase();
      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {
          'endpoint': 'distancematrix',
          'params': {
            'origins': '$lat1,$lng1',
            'destinations': '$lat2,$lng2',
            'mode': gMode
          }
        },
      );

      if (response.status == 200) {
        final Map<String, dynamic> data = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        if (data['status'] == 'OK' &&
            data['rows'] != null &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].isNotEmpty &&
            data['rows'][0]['elements'][0]['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          return {
            'distance': element['distance']['value'], // meters
            'duration': element['duration']['value'], // seconds
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Distance Matrix error: $e');
      return null;
    }
  }

  String? _extractCountryCode(dynamic addressComponents) {
    if (addressComponents == null || addressComponents is! List) return null;
    for (var component in addressComponents) {
      final types = component['types'] as List?;
      if (types != null && types.contains('country')) {
        return component['short_name'];
      }
    }
    return null;
  }
}
