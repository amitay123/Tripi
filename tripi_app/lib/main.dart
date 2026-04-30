import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'screens/set_new_password_screen.dart';

Future<void> main() async {
  debugPrint('App initialization started');
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Google Fonts runtime fetching to avoid white screen crash when fonts are missing from assets.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fbtoyhnjwyhssozetfhw.supabase.co',
    anonKey: 'sb_publishable_DWgDyHuCNZLMHIbIkVuCkA_eTe_Z4Vw',
  );

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL ERROR: ${details.exception}');
  };

  debugPrint('Supabase initialized, starting app');
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

class TripiApp extends StatefulWidget {
  const TripiApp({super.key});

  @override
  State<TripiApp> createState() => _TripiAppState();
}

class _TripiAppState extends State<TripiApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      debugPrint('AUTH EVENT RECEIVED: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('PASSWORD RECOVERY DETECTED - Navigating to reset screen');
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/set-new-password',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        '/set-new-password': (context) => const SetNewPasswordScreen(),
      },
    );
  }
}
