import '../../models/timeline_models.dart';

class AirportCatalog {
  static const airports = [
    Airport(
      airportName: 'Ben Gurion Airport',
      city: 'Tel Aviv',
      country: 'Israel',
      iataCode: 'TLV',
    ),
    Airport(
      airportName: 'John F. Kennedy International Airport',
      city: 'New York',
      country: 'United States',
      iataCode: 'JFK',
    ),
    Airport(
      airportName: 'Heathrow Airport',
      city: 'London',
      country: 'United Kingdom',
      iataCode: 'LHR',
    ),
    Airport(
      airportName: 'Charles de Gaulle Airport',
      city: 'Paris',
      country: 'France',
      iataCode: 'CDG',
    ),
    Airport(
      airportName: 'Los Angeles International Airport',
      city: 'Los Angeles',
      country: 'United States',
      iataCode: 'LAX',
    ),
    Airport(
      airportName: 'Dubai International Airport',
      city: 'Dubai',
      country: 'United Arab Emirates',
      iataCode: 'DXB',
    ),
    Airport(
      airportName: 'Amsterdam Airport Schiphol',
      city: 'Amsterdam',
      country: 'Netherlands',
      iataCode: 'AMS',
    ),
    Airport(
      airportName: 'Adolfo Suarez Madrid-Barajas Airport',
      city: 'Madrid',
      country: 'Spain',
      iataCode: 'MAD',
    ),
    Airport(
      airportName: 'Leonardo da Vinci-Fiumicino Airport',
      city: 'Rome',
      country: 'Italy',
      iataCode: 'FCO',
    ),
    Airport(
      airportName: 'Istanbul Airport',
      city: 'Istanbul',
      country: 'Turkey',
      iataCode: 'IST',
    ),
    Airport(
      airportName: 'Tokyo Haneda Airport',
      city: 'Tokyo',
      country: 'Japan',
      iataCode: 'HND',
    ),
    Airport(
      airportName: 'Narita International Airport',
      city: 'Tokyo',
      country: 'Japan',
      iataCode: 'NRT',
    ),
    Airport(
      airportName: 'Velana International Airport',
      city: 'Male',
      country: 'Maldives',
      iataCode: 'MLE',
    ),
    Airport(
      airportName: 'Suvarnabhumi Airport',
      city: 'Bangkok',
      country: 'Thailand',
      iataCode: 'BKK',
    ),
    Airport(
      airportName: 'Singapore Changi Airport',
      city: 'Singapore',
      country: 'Singapore',
      iataCode: 'SIN',
    ),
  ];

  static List<Airport> search(String query) {
    final matches = airports.where((airport) => airport.matches(query)).toList();
    matches.sort((a, b) => a.iataCode.compareTo(b.iataCode));
    return matches;
  }

  static Airport? byIata(String? iataCode) {
    if (iataCode == null || iataCode.trim().isEmpty) return null;
    final normalized = iataCode.trim().toUpperCase();
    for (final airport in airports) {
      if (airport.iataCode == normalized) return airport;
    }
    return null;
  }
}
