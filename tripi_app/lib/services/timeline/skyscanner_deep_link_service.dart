import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SkyscannerDeepLinkService {
  /// Builds a Skyscanner URL for flight search and redirects the user.
  /// 
  /// TODO: Replace this URL structure with the official Skyscanner Affiliate / Referral API
  /// when available to enable tracking and monetization.
  static Future<void> launchFlightSearch({
    required String originAirportIata,
    required String destinationAirportIata,
    required DateTime departureDate,
    required DateTime returnDate,
    int adults = 1,
    int children = 0,
    List<int> childAges = const [],
    int infants = 0,
    String cabinClass = 'economy',
    String locale = 'en-US',
    String currency = 'USD',
  }) async {
    final DateFormat formatter = DateFormat('yyMMdd');
    final String depDateStr = formatter.format(departureDate);
    final String retDateStr = formatter.format(returnDate);

    // Skyscanner URL format:
    // https://www.skyscanner.com/transport/flights/{origin}/{destination}/{YYMMDD}/{YYMMDD}/?adults={adults}&childrenv2={children}&infants={infants}&cabinclass={cabinclass}&locale={locale}&currency={currency}
    
    final uri = Uri.parse(
      'https://www.skyscanner.com/transport/flights/$originAirportIata/$destinationAirportIata/$depDateStr/$retDateStr/?adultsv2=$adults&childrenv2=$children&infants=$infants&cabinclass=$cabinClass&locale=$locale&currency=$currency'
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch Skyscanner URL: $uri');
    }
  }

  static String destinationAirportIata({
    required String destinationName,
    required String country,
  }) {
    final key = destinationName.trim().toLowerCase();
    final countryKey = country.trim().toLowerCase();
    const byDestination = {
      'paris': 'CDG',
      'maldives': 'MLE',
      'tokyo': 'HND',
    };
    const byCountry = {
      'france': 'CDG',
      'maldives': 'MLE',
      'japan': 'HND',
    };
    return byDestination[key] ?? byCountry[countryKey] ?? key.toUpperCase();
  }
}
