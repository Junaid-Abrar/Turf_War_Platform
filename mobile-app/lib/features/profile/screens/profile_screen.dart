import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/user_provider.dart';

/// Account screen.
///
/// Logout used to be an unlabelled icon in the home app bar. It now lives here
/// alongside the account details; Phase 5 adds avatar, stats and the theme
/// toggle on top of this scaffold.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to book a turf.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    // The router's redirect sends the user to login once the status flips.
    await context.read<UserProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel? user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user?.initial ?? '?',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Guest',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 8),
                if (user != null)
                  Chip(
                    label: Text(_roleLabel(user.role)),
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('My bookings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(AppRoutes.myBookings),
          ),
          if (user?.canManageVenues ?? false)
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Add a venue'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goNamed(AppRoutes.addVenue),
            ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 24),
          if (AppConfig.demoMode)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Demo mode: payments are simulated and push notifications '
                  'are disabled.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'venue_owner':
        return 'Venue owner';
      default:
        return 'Player';
    }
  }
}
