import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/set_new_password_screen.dart';
import 'providers/booking_provider.dart';
import 'theme/tripi_theme.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
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
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('--- Password Recovery Event Detected ---');
        _navigatorKey.currentState?.pushNamed('/set-new-password');
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
        '/explore': (context) => const ExploreScreen(),
        '/itinerary': (context) => const ItineraryScreen(),
        '/set-new-password': (context) => const SetNewPasswordScreen(),
      },
    );
  }
}
