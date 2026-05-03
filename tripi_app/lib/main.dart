import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
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
import 'models/models.dart' as models;


import 'screens/registration_screen.dart';
import 'screens/admin/admin_scaffold.dart';
import 'screens/set_new_password_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) debugPrint('Error: ${record.error}');
    if (record.stackTrace != null) debugPrint('StackTrace: ${record.stackTrace}');
  });

  final log = Logger('TripiApp');
  log.info('App initialization started');
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Google Fonts runtime fetching to avoid white screen crash when fonts are missing from assets.
  GoogleFonts.config.allowRuntimeFetching = true;

  log.info('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://fbtoyhnjwyhssozetfhw.supabase.co',
    anonKey: 'sb_publishable_DWgDyHuCNZLMHIbIkVuCkA_eTe_Z4Vw',
  );
  log.info('Supabase initialized successfully');

  // Check if we should clear the session based on "Remember Me" preference
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? false;
  if (!rememberMe) {
    log.info('Remember Me is false, signing out to prevent auto-login');
    await Supabase.instance.client.auth.signOut();
  }

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.severe('GLOBAL ERROR: ${details.exception}', details.exception, details.stack);
  };

  log.info('Starting runApp...');
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
    final log = Logger('TripiApp.Auth');
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      log.info('***** AUTH EVENT: $event | URL: ${Uri.base}');

      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/set-new-password',
          (route) => false,
        );
      } else if (event == AuthChangeEvent.initialSession) {
        // This fires on app load. Two cases:
        // 1. URL has ?intent= → coming back from OAuth redirect → run full logic
        // 2. No intent in URL → regular page refresh → auto-login if session exists
        final session = data.session;
        if (session != null) {
          final hasIntent = Uri.base.queryParameters.containsKey('intent');
          log.info('***** INITIAL SESSION: hasIntent=$hasIntent, user=${session.user.email}');
          if (hasIntent) {
            // OAuth redirect just completed
            _handleSocialAuthLogic(session.user);
          } else {
            // Regular page refresh with a valid session – go straight to app
            _handleExistingSession(session.user);
          }
        }
        // If session == null, the user is not logged in → stay on LoginScreen (initialRoute '/')
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        final session = data.session;
        if (session != null) {
          log.info('***** SIGNED IN: ${session.user.email}');
          _handleSocialAuthLogic(session.user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        final navContext = _navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          Provider.of<BookingProvider>(navContext, listen: false).updateUser(null);
        }
        _navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  /// Called on a regular page refresh where the user already has a valid session.
  Future<void> _handleExistingSession(User user) async {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;

    final email = user.email ?? '';
    final log = Logger('TripiApp.Auth');
    try {
      final isRegistered = await SupabaseService.isUserRegistered(email);
      if (!mounted) return;
      
      if (!isRegistered) {
        log.warning('***** EXISTING SESSION but user not in profiles. Signing out.');
        await SupabaseService.signOut();
        return;
      }
      if (!mounted || !navContext.mounted) return;
      final bookingProvider = Provider.of<BookingProvider>(navContext, listen: false);
      bookingProvider.updateUser(models.User(
        id: user.id,
        email: email,
        name: user.userMetadata?['full_name']?.toString() ??
              user.userMetadata?['name']?.toString() ?? 'Traveler',
        profileImage: user.userMetadata?['avatar_url']?.toString() ??
                      user.userMetadata?['picture']?.toString(),
        providerType: user.appMetadata['provider']?.toString(),
      ));
      log.info('***** EXISTING SESSION valid – navigating to explore');
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/explore', (route) => false);
    } catch (e) {
      log.severe('***** EXISTING SESSION ERROR: $e');
    }
  }

  Future<void> _handleSocialAuthLogic(User user) async {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;

    final log = Logger('TripiApp.Auth');
    final bookingProvider = Provider.of<BookingProvider>(navContext, listen: false);

    // Read intent from the current URL – this survives the OAuth redirect
    final uri = Uri.base;
    final intent = uri.queryParameters['intent']; // 'login', 'register', or null

    final email = user.email ?? '';
    final name = user.userMetadata?['full_name']?.toString() ??
                 user.userMetadata?['name']?.toString() ??
                 'Traveler';

    log.info('***** SOCIAL AUTH LOGIC: Intent=$intent, Email=$email, URL=${uri.toString()}');

    try {
      final isRegistered = await SupabaseService.isUserRegistered(email);
      if (!mounted) return;
      
      log.info('***** IS REGISTERED: $isRegistered');

      if (intent == 'login') {
        if (!isRegistered) {
          // User tried to login but is not registered
          log.warning('***** LOGIN FAILED: User not registered');
          await SupabaseService.signOut();
          if (!mounted || !navContext.mounted) return;
          ScaffoldMessenger.of(navContext).showSnackBar(
            const SnackBar(
              content: Text('המייל לא נמצא במערכת, עליך להירשם תחילה'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        // User exists → login success → fall through to navigate
      } else if (intent == 'register') {
        if (isRegistered) {
          // User tried to register but already exists
          log.warning('***** REGISTER FAILED: User already exists');
          await SupabaseService.signOut();
          if (!mounted || !navContext.mounted) return;
          ScaffoldMessenger.of(navContext).showSnackBar(
            const SnackBar(
              content: Text('המייל כבר קיים במערכת, אנא התחבר'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        // New user → create profile in DB
        log.info('***** REGISTER SUCCESS: Creating profile');
        await SupabaseService.createProfile(
          id: user.id,
          email: email,
          name: name,
        );
        if (!mounted) return;
        // Fall through to navigate
      } else {
        // intent == null → existing session (page refresh)
        if (!isRegistered) {
          log.warning('***** SESSION INVALID: User not in profiles. Signing out.');
          await SupabaseService.signOut();
          return;
        }
        // Valid existing session → fall through to navigate
      }

      // ✅ Success – update local state and navigate to app
      final userModel = models.User(
        id: user.id,
        email: email,
        name: name,
        profileImage: user.userMetadata?['avatar_url']?.toString() ??
                      user.userMetadata?['picture']?.toString(),
        providerType: user.appMetadata['provider']?.toString(),
      );

      bookingProvider.updateUser(userModel);

      log.info('***** NAVIGATING TO EXPLORE');
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/explore', (route) => false);
    } catch (e, st) {
      log.severe('***** SOCIAL AUTH ERROR: $e', e, st);
    }
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
