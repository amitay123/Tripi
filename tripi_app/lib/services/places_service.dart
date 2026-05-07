import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/place_result.dart';
import 'place_provider.dart';

class PlacesService implements PlaceProvider {
  // Singleton pattern
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _parseAutocompleteResponse(dynamic data) {
    try {
      final Map<String, dynamic> json =
          data is String ? jsonDecode(data) : data;
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


  String? getPhotoUrl(String? photoReference) {
    if (photoReference == null || photoReference.isEmpty) return null;

    // If it's already a full URL, return it directly (or proxy it if needed for CORS)
    if (photoReference.startsWith('http')) {
      // Avoid double-proxying
      if (photoReference.contains('weserv.nl')) return photoReference;
      
      // For web, we still might want to proxy to avoid CORS issues if it's from a strict domain
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(photoReference)}';
    }

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
        final Map<String, dynamic> data =
            response.data is String ? jsonDecode(response.data) : response.data;
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

  Future<List<Map<String, dynamic>>> searchPlaces({
    required double lat,
    required double lng,
    String? type,
    String? keyword,
    int radius = 5000,
  }) async {
    try {
      final Map<String, String> params = {
        'location': '$lat,$lng',
        'radius': radius.toString(),
      };
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {
          'endpoint': 'nearbysearch',
          'params': params,
        },
      );

      if (response.status == 200) {
        final Map<String, dynamic> data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Search places error: $e');
      return [];
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

  // --- PlaceProvider Implementation ---

  @override
  Future<List<PlaceResult>> searchNearby({
    required double lat,
    required double lng,
    String? type,
    String? keyword,
    int radius = 5000,
    int maxResults = 20,
  }) async {
    final cacheKey = 'nearby_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}_${radius}_${type ?? ''}_${keyword ?? ''}';
    
    // Check cache
    if (_discoveryCache.containsKey(cacheKey)) {
      return _discoveryCache[cacheKey]!;
    }

    try {
      final Map<String, String> params = {
        'location': '$lat,$lng',
        'radius': radius.toString(),
      };
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

      final response = await _supabase.functions.invoke(
        'places-proxy',
        body: {
          'endpoint': 'nearbysearch',
          'params': params,
        },
      );

      if (response.status == 200) {
        final Map<String, dynamic> data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data['results'] != null) {
          final results = (data['results'] as List)
              .map((e) {
                final photoRef = (e['photos'] != null && (e['photos'] as List).isNotEmpty)
                    ? e['photos'][0]['photo_reference']
                    : null;
                return PlaceResult.fromJson(
                  Map<String, dynamic>.from(e),
                  imageUrl: getPhotoUrl(photoRef),
                );
              })
              .take(maxResults)
              .toList();
          
          _discoveryCache[cacheKey] = results;
          return results;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Search places error: $e');
      return [];
    }
  }

  @override
  Future<PlaceResult?> getPlaceDetails(String placeId) async {
    final details = await getPlaceDetailsRaw(placeId);
    if (details == null) return null;
    
    // Ensure image_url is populated if we have photo references
    final photoRefs = details['photo_references'] as List?;
    final firstPhoto = (photoRefs != null && photoRefs.isNotEmpty) ? photoRefs[0] : null;
    
    return PlaceResult.fromMap({
      ...details,
      if (details['image_url'] == null && firstPhoto != null)
        'image_url': getPhotoUrl(firstPhoto),
    });
  }

  // Renamed original detail fetcher for internal use
  Future<Map<String, dynamic>?> getPlaceDetailsRaw(String placeId) async {
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
        final Map<String, dynamic> data =
            response.data is String ? jsonDecode(response.data) : response.data;
        final result = data['result'];
        if (result != null) {
          return {
            'place_id': placeId,
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

  // --- Discovery Caching & Batching ---
  
  final Map<String, List<PlaceResult>> _discoveryCache = {};
  
  void clearCache() => _discoveryCache.clear();

  // Helper for route sampling searches
  Future<List<PlaceResult>> searchBatch(List<Map<String, dynamic>> searchQueries) async {
    final List<PlaceResult> allResults = [];
    final Set<String> seenPlaceIds = {};
    
    // Controlled concurrency: process in chunks to avoid blocking the UI and stay within rate limits
    const int chunkSize = 10;
    for (int i = 0; i < searchQueries.length; i += chunkSize) {
      final chunk = searchQueries.sublist(
        i, 
        (i + chunkSize) > searchQueries.length ? searchQueries.length : i + chunkSize
      );
      
      final results = await Future.wait(chunk.map((point) => searchNearby(
        lat: point['lat'],
        lng: point['lng'],
        radius: point['radius'] ?? 1000,
        type: point['type'],
        keyword: point['keyword'],
        maxResults: 10,
      )));

      for (var resultList in results) {
        for (var res in resultList) {
          if (!seenPlaceIds.contains(res.placeId)) {
            seenPlaceIds.add(res.placeId);
            allResults.add(res);
          }
        }
      }
      
      // Minimal delay between chunks if needed
      if (i + chunkSize < searchQueries.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    return allResults;
  }
}
