import 'package:url_launcher/url_launcher.dart';

class ExternalBookingService {
  /// Builds a Skyscanner URL for flight search and redirects the user.
  /// Currently uses a placeholder URL as requested, but keeps the structure ready.
  static Future<void> buildSkyscannerUrl({
    required String origin,
    required String destination,
    required DateTime departureDate,
    required DateTime returnDate,
  }) async {
    // In the future, this will build a real Skyscanner URL with affiliate parameters.
    // e.g., https://www.skyscanner.com/transport/flights/{origin}/{destination}/{departureDate}/{returnDate}
    
    // Formatting dates to YYYY-MM-DD
    // final depDateStr = ...
    // final retDateStr = ...
    
    final url = Uri.parse('https://www.skyscanner.com/');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
