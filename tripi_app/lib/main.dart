import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/tripi_theme.dart';
import 'providers/booking_provider.dart';
import 'providers/trip_provider.dart';
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
  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL ERROR: ${details.exception}');
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
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
      // Global error widget
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(details.exception.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
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
