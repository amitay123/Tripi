import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/tripi_theme.dart';
import 'providers/booking_provider.dart';
import 'screens/login_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/place_details_screen.dart';
import 'screens/flight_search_screen.dart';
import 'screens/seat_selection_screen.dart';
import 'screens/baggage_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/ticket_screen.dart';

import 'screens/registration_screen.dart';
import 'screens/admin/admin_scaffold.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const TripiApp(),
    ),
  );
}

class TripiApp extends StatelessWidget {
  const TripiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tripi',
      debugShowCheckedModeBanner: false,
      theme: TripiTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/explore': (context) => const MainScaffold(),
        '/place-details': (context) => const PlaceDetailsScreen(),
        '/flight-search': (context) => const FlightSearchScreen(),
        '/seat-selection': (context) => const SeatSelectionScreen(),
        '/baggage': (context) => const BaggageScreen(),
        '/confirmation': (context) => const ConfirmationScreen(),
        '/ticket': (context) => const TicketScreen(),
        '/admin': (context) => const AdminScaffold(),
      },
    );
  }
}
