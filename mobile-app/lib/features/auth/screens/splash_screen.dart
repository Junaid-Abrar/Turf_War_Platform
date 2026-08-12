import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

/// Shown while the stored token is validated.
///
/// This used to wait two artificial seconds and then `pushReplacement` to home
/// or login itself. Now it only kicks off [UserProvider.tryAutoLogin]; the
/// router's redirect moves on as soon as the auth status resolves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.sports_soccer,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'TURF WAR',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
