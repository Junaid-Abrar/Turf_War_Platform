import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// What a [StatusBadge] is communicating. Kept independent of the booking
/// model's string statuses so the badge is reusable for payment state too.
enum StatusTone { success, warning, danger, info, neutral }

/// A small pill showing a booking or payment status.
///
/// Replaces the private `_StatusBadge` that lived in `my_bookings_screen.dart`
/// and hardcoded `Colors.green` / `Colors.orange` — neither of which had enough
/// contrast on a dark surface. Colours now resolve through the theme extension,
/// so the badge is legible in both brightnesses.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  /// Maps a booking's `status` field to a badge.
  factory StatusBadge.forBookingStatus(String status) {
    return switch (status) {
      'confirmed' => const StatusBadge(
          label: 'Confirmed',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        ),
      'pending' => const StatusBadge(
          label: 'Pending',
          tone: StatusTone.warning,
          icon: Icons.schedule,
        ),
      'cancelled' => const StatusBadge(
          label: 'Cancelled',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        ),
      'completed' => const StatusBadge(
          label: 'Completed',
          tone: StatusTone.info,
          icon: Icons.done_all,
        ),
      // An unrecognised status is shown verbatim rather than hidden, so a new
      // backend status is visible rather than silently rendering as blank.
      _ => StatusBadge(label: status, tone: StatusTone.neutral),
    };
  }

  /// Maps a booking's `paymentStatus` field to a badge.
  factory StatusBadge.forPaymentStatus(String paymentStatus) {
    return switch (paymentStatus) {
      'paid' => const StatusBadge(
          label: 'Paid',
          tone: StatusTone.success,
          icon: Icons.payments_outlined,
        ),
      'refunded' => const StatusBadge(
          label: 'Refunded',
          tone: StatusTone.info,
          icon: Icons.undo,
        ),
      _ => const StatusBadge(
          label: 'Unpaid',
          tone: StatusTone.warning,
          icon: Icons.payments_outlined,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final (Color foreground, Color background) = switch (tone) {
      StatusTone.success => (
          semantic.onSuccessContainer,
          semantic.successContainer,
        ),
      StatusTone.warning => (
          semantic.onWarningContainer,
          semantic.warningContainer,
        ),
      StatusTone.danger => (
          semantic.onDangerContainer,
          semantic.dangerContainer,
        ),
      StatusTone.info => (semantic.onInfoContainer, semantic.infoContainer),
      StatusTone.neutral => (
          colors.onSurfaceVariant,
          colors.surfaceContainerHighest,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            AppSpacing.hGapXs,
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
