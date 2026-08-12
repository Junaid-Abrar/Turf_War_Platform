/// Compile-time application configuration.
///
/// Every value here is supplied via `--dart-define` so that no environment-specific
/// URL or key is ever committed. Defaults point at a local backend so a fresh
/// checkout runs against `npm run dev` without any extra flags.
///
/// See `.env.example` for the full list of keys and `run.sh` for a wrapper that
/// passes them.
class AppConfig {
  const AppConfig._();

  /// Base URL of the REST API, including the `/api` prefix.
  ///
  /// Android emulators cannot reach the host's `localhost`, so the default uses
  /// `10.0.2.2` — the emulator's alias for the host machine.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Stripe publishable key. Empty means "no key configured" — the app then
  /// skips Stripe initialisation rather than crashing on a placeholder value.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  /// Demo mode stubs out integrations that cannot run in a public web demo
  /// (the Stripe payment sheet, FCM registration) and surfaces a banner so the
  /// limitation is visible rather than hidden.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  /// Network timeout applied to both connect and receive phases.
  static const Duration requestTimeout = Duration(seconds: 20);

  static bool get hasStripeKey => stripePublishableKey.isNotEmpty;
}
