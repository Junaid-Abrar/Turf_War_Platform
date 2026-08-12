import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// One of the seeded demo logins.
@immutable
class DemoAccount {
  final String label;
  final String description;
  final String email;
  final String password;
  final IconData icon;

  const DemoAccount({
    required this.label,
    required this.description,
    required this.email,
    required this.password,
    required this.icon,
  });
}

/// The accounts created by `backend/scripts/seed.js`.
///
/// Kept in sync with that script's `USERS` list and `DEMO_PASSWORD` by hand —
/// there are three of them and they only change when the seed does, so wiring
/// an endpoint to serve them would cost more than it saves.
const List<DemoAccount> demoAccounts = <DemoAccount>[
  DemoAccount(
    label: 'Player',
    description: 'Browse venues, book a slot and pay',
    email: 'user@turfwar.demo.com',
    password: 'password123',
    icon: Icons.sports_soccer,
  ),
  DemoAccount(
    label: 'Venue owner',
    description: 'Everything a player can do, plus listing venues',
    email: 'owner@turfwar.demo.com',
    password: 'password123',
    icon: Icons.storefront_outlined,
  ),
  DemoAccount(
    label: 'Administrator',
    description: 'Full access, including the admin dashboard',
    email: 'admin@turfwar.demo.com',
    password: 'password123',
    icon: Icons.admin_panel_settings_outlined,
  ),
];

/// Lets the user pick a seeded account to sign in with.
///
/// Returns the chosen account, or null if the sheet was dismissed.
Future<DemoAccount?> showDemoCredentialsSheet(BuildContext context) {
  return showModalBottomSheet<DemoAccount>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Demo accounts', style: theme.textTheme.headlineSmall),
              AppSpacing.gapXs,
              Text(
                'Each role sees a different part of the app. Pick one to sign '
                'in immediately.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXl,
              for (final DemoAccount account in demoAccounts) ...<Widget>[
                AppCard(
                  onTap: () => Navigator.of(sheetContext).pop(account),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Icon(account.icon, size: 20),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              account.label,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              account.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
              ],
            ],
          ),
        ),
      );
    },
  );
}
