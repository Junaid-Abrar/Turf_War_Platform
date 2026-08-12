import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/user_provider.dart';

/// Shown while the stored token is validated.
///
/// This used to wait two artificial seconds and then `pushReplacement` to home
/// or login itself. It now only kicks off [UserProvider.tryAutoLogin]; the
/// router's redirect moves on as soon as the auth status resolves. The
/// animation is purely a cover for that real wait — nothing is gated on it, so
/// a fast auto-login is not held back by it finishing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.splash,
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    // A slight overshoot so the mark lands with some weight rather than simply
    // appearing.
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();

    // Deferred so the first frame renders before the network call starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final UserProvider provider = context.read<UserProvider>();
      if (provider.status == AuthStatus.unknown) {
        provider.tryAutoLogin();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ScaleTransition(
              scale: _logoScale,
              child: const TurfWarLogo(size: 96),
            ),
            AppSpacing.gapXxl,
            FadeTransition(
              opacity: _fade,
              child: Text(
                'TURF WAR',
                style: AppTypography.wordmark.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            AppSpacing.gapSm,
            FadeTransition(
              opacity: _fade,
              child: Text(
                'Book your pitch by the hour',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AppSpacing.gapHuge,
            FadeTransition(
              opacity: _fade,
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
