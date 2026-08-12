import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/logger.dart';
import 'features/auth/providers/user_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/bookings/providers/booking_provider.dart';
import 'features/bookings/services/booking_service.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/payments/services/payment_service.dart';
import 'features/venues/providers/venue_provider.dart';
import 'features/venues/services/venue_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('Background message: ${message.messageId}');
}

Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  // Holds the native splash on screen until the first Flutter frame is ready,
  // so there is no blank window between the two.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await _initFirebase();
  await _initStripe();

  // Read before the first frame: loading the theme lazily would paint the
  // default light theme and then swap to dark a frame later.
  final ThemeProvider themeProvider = await ThemeProvider.load();

  runApp(TurfWarApp(themeProvider: themeProvider));

  FlutterNativeSplash.remove();
}

/// Firebase powers chat and push. A missing or misconfigured
/// `google-services.json` should degrade those features, not stop the app from
/// starting.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    if (!AppConfig.demoMode) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }
  } catch (e, s) {
    AppLogger.error('Firebase initialisation failed', e, s);
  }
}

/// The publishable key now comes from `--dart-define` rather than the
/// `pk_test_placeholder` literal that used to be committed. With no key
/// configured, Stripe is left uninitialised and [PaymentProvider] simulates the
/// sheet instead of throwing at the point of payment.
Future<void> _initStripe() async {
  if (!AppConfig.hasStripeKey) {
    AppLogger.info('No Stripe key configured; payments run in simulated mode');
    return;
  }
  try {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  } catch (e, s) {
    AppLogger.error('Stripe initialisation failed', e, s);
  }
}

class TurfWarApp extends StatefulWidget {
  /// Loaded in [main] before the first frame so the app opens directly in the
  /// user's saved theme.
  final ThemeProvider themeProvider;

  const TurfWarApp({super.key, required this.themeProvider});

  @override
  State<TurfWarApp> createState() => _TurfWarAppState();
}

class _TurfWarAppState extends State<TurfWarApp> {
  // Built once in initState rather than inline in build, so a rebuild does not
  // discard the router (and with it the navigation stack) or the ApiClient.
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final VenueService _venueService;
  late final BookingService _bookingService;
  late final PaymentService _paymentService;
  late final NotificationService _notificationService;
  late final UserProvider _userProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _tokenStorage = TokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);

    _authService = AuthService(_apiClient);
    _venueService = VenueService(_apiClient);
    _bookingService = BookingService(_apiClient);
    _paymentService = PaymentService(_apiClient);
    _notificationService = NotificationService(_authService);

    _userProvider = UserProvider(
      authService: _authService,
      tokenStorage: _tokenStorage,
      notificationService: _notificationService,
    );

    // Any 401 anywhere in the app clears the session; the router's redirect
    // then moves the user to the login screen. No screen has to handle this.
    _apiClient.onUnauthorized = _userProvider.logout;

    _router = buildRouter(_userProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        Provider<VenueService>.value(value: _venueService),
        Provider<BookingService>.value(value: _bookingService),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        ChangeNotifierProvider<VenueProvider>(
          create: (_) => VenueProvider(_venueService),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(_bookingService),
        ),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => PaymentProvider(_paymentService),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: widget.themeProvider,
        ),
      ],
      // Only the MaterialApp rebuilds when the theme preference changes; the
      // providers above it are untouched, so switching themes does not discard
      // any in-flight request or cached list.
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider themeProvider, _) {
          return MaterialApp.router(
            title: 'Turf War',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
