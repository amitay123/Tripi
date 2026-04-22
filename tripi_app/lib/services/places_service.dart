import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PlacesService {
  // Singleton pattern
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  static const String _apiKey = 'AIzaSyDNxKWoy8qIDOMyO8FTf1DED_wByeKzm2M';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<Map<String, dynamic>>> autocompletePlaces(String input, {String? countryCode, double? lat, double? lng}) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey';
      if (countryCode != null && countryCode.isNotEmpty) url += '&components=country:$countryCode';
      if (lat != null && lng != null) url += '&location=$lat,$lng&radius=50000';

      final Uri uri = kIsWeb 
        ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
        : Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> autocompleteCountries(String input) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(regions)&key=$_apiKey';
      final Uri uri = kIsWeb 
        ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
        : Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> autocompleteCities(String input, String? countryCode) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(cities)&key=$_apiKey';
      if (countryCode != null && countryCode.isNotEmpty) url += '&components=country:$countryCode';
      
      final Uri uri = kIsWeb 
        ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
        : Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,geometry,photos,types,address_components&key=$_apiKey';
      
      final Uri uri = kIsWeb 
        ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
        : Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        if (result != null) {
          return {
            'name': result['name'],
            'formatted_address': result['formatted_address'],
            'lat': result['geometry']['location']['lat'],
            'lng': result['geometry']['location']['lng'],
            'photo_reference': (result['photos'] != null && result['photos'].isNotEmpty) 
                ? result['photos'][0]['photo_reference'] 
                : null,
            'types': result['types'] != null ? List<String>.from(result['types']) : [],
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
    final String url = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$photoReference&key=$_apiKey';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
  }

  Future<Map<String, dynamic>?> getDistanceAndDuration(
    double lat1, double lng1, double lat2, double lng2, String mode
  ) async {
    try {
      final String gMode = mode == 'flight' ? 'driving' : mode.toLowerCase();
      final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$lat1,$lng1&destinations=$lat2,$lng2&mode=$gMode&key=$_apiKey';
      
      final Uri uri = kIsWeb 
        ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
        : Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
