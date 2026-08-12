import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../bookings/providers/booking_provider.dart';

/// Account screen: identity, a summary of the user's activity, appearance
/// settings and the way out.
///
/// Logout used to be an unlabelled icon in the home app bar, with no profile
/// screen at all.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The stats below are derived from the bookings list, which may not have
    // been loaded yet if the user came straight here from the home screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BookingProvider provider = context.read<BookingProvider>();
      if (provider.myBookings.isEmpty) provider.fetchMyBookings();
    });
  }

  Future<void> _confirmLogout() async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    // The router's redirect sends the user to login once the status flips.
    await context.read<UserProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel? user = context.watch<UserProvider>().user;
    final BookingProvider bookings = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.goNamed(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _Identity(user: user),
          AppSpacing.gapXl,
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  value: '${bookings.upcomingBookings.length}',
                  label: 'Upcoming',
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: _StatTile(
                  icon: Icons.history,
                  value: '${bookings.pastBookings.length}',
                  label: 'Played',
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_outlined,
                  value: '\$${_totalSpent(bookings).toStringAsFixed(0)}',
                  label: 'Spent',
                ),
              ),
            ],
          ),
          AppSpacing.gapXxl,
          const SectionHeader(title: 'Activity'),
          AppSpacing.gapSm,
          _SettingsGroup(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('My bookings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed(AppRoutes.myBookings),
              ),
              if (user?.canManageVenues ?? false) ...<Widget>[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_business_outlined),
                  title: const Text('List a venue'),
                  subtitle: const Text('Put your pitch on the platform'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.goNamed(AppRoutes.addVenue),
                ),
              ],
            ],
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: 'Appearance'),
          AppSpacing.gapSm,
          const _SettingsGroup(children: <Widget>[_ThemeSelector()]),
          AppSpacing.gapXl,
          const SectionHeader(title: 'Account'),
          AppSpacing.gapSm,
          _SettingsGroup(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'Log out',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: _confirmLogout,
              ),
            ],
          ),
          if (AppConfig.demoMode) ...<Widget>[
            AppSpacing.gapXl,
            const _DemoModeNotice(),
          ],
          AppSpacing.gapXl,
          Center(
            child: Text(
              'Turf War · v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Only paid bookings count — an unpaid or cancelled one has not cost the
  /// user anything.
  double _totalSpent(BookingProvider provider) {
    return provider.myBookings
        .where((booking) => booking.isPaid && !booking.isCancelled)
        .fold<double>(0, (double sum, booking) => sum + booking.price);
  }
}

/// Avatar, name, email and role.
class _Identity extends StatelessWidget {
  final UserModel? user;

  const _Identity({required this.user});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user?.initial ?? '?',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        AppSpacing.gapMd,
        Text(user?.name ?? 'Guest', style: theme.textTheme.headlineSmall),
        AppSpacing.gapXxs,
        Text(
          user?.email ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (user != null) ...<Widget>[
          AppSpacing.gapSm,
          StatusBadge(
            label: _roleLabel(user!.role),
            tone: user!.isAdmin ? StatusTone.info : StatusTone.success,
            icon: user!.canManageVenues
                ? Icons.verified_outlined
                : Icons.sports_soccer,
          ),
        ],
      ],
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'Administrator',
      'venue_owner' => 'Venue owner',
      _ => 'Player',
    };
  }
}

/// One figure in the stats row.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          AppSpacing.gapSm,
          Text(
            value,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A bordered container grouping related rows, so the settings list reads as
/// sections rather than one undifferentiated run of tiles.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

/// Light / dark / system selector.
///
/// A three-way segmented control rather than a switch: "follow the system" is
/// the default and a two-state switch cannot express it.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final ThemeProvider provider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.palette_outlined),
              AppSpacing.hGapMd,
              Text('Theme', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          AppSpacing.gapMd,
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 18),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 18),
                label: Text('Auto'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 18),
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{provider.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (Set<ThemeMode> selection) =>
                provider.setThemeMode(selection.first),
          ),
        ],
      ),
    );
  }
}

/// Explains what is stubbed out in the hosted demo, so a reviewer does not
/// mistake a simulated payment for a broken one.
class _DemoModeNotice extends StatelessWidget {
  const _DemoModeNotice();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return AppCard(
      color: semantic.infoContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: semantic.onInfoContainer, size: 20),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Demo mode',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: semantic.onInfoContainer,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  'Payments are simulated and push notifications are off. '
                  'Everything else talks to the real API.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: semantic.onInfoContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
