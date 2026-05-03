import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class HotelService {
  // Singleton pattern
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  /// Generates a deep link to Booking.com for a specific hotel.
  Future<void> launchBooking(String hotelName, String city) async {
    final query = Uri.encodeComponent('$hotelName $city');
    final url = Uri.parse('https://www.booking.com/searchresults.html?ss=$query');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Booking.com: $url');
    }
  }

  /// Generates a deep link to Agoda for a specific hotel.
  Future<void> launchAgoda(String hotelName, String city) async {
    final query = Uri.encodeComponent('$hotelName $city');
    final url = Uri.parse('https://www.agoda.com/search?text=$query');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Agoda: $url');
    }
  }

  /// Returns a simulated "best price" for a hotel.
  /// In a real app, this would fetch from a comparison API.
  Map<String, dynamic> getSimulatedPricing(String hotelName) {
    final int seed = hotelName.hashCode.abs();
    final double basePrice = (seed % 200) + 100.0; // $100 - $300
    
    return {
      'booking': {
        'price': basePrice + (seed % 20),
        'currency': 'USD',
        'rating': 8.5 + (seed % 10) / 10,
      },
      'agoda': {
        'price': basePrice + (seed % 15),
        'currency': 'USD',
        'rating': 8.3 + (seed % 15) / 10,
      }
    };
  }
}
