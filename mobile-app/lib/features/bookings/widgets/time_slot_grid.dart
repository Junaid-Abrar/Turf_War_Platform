import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Why a slot cannot be picked, or that it can.
///
/// Modelled as an enum rather than the two booleans this used to be: "booked"
/// and "already past" are different facts and deserve different labels, and a
/// boolean pair makes the impossible fourth combination representable.
enum SlotState { available, booked, past, selected }

/// The bookable hours for a day.
class TimeSlotGrid extends StatelessWidget {
  final List<String> slots;
  final SlotState Function(String slot) stateFor;
  final ValueChanged<String> onSelected;

  /// Blocks interaction while a booking is in flight.
  final bool enabled;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.stateFor,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: slots.length,
      itemBuilder: (BuildContext context, int index) {
        final String slot = slots[index];
        final SlotState state = stateFor(slot);
        return _SlotTile(
          label: slot,
          state: state,
          onTap: (!enabled || state != SlotState.available)
              ? null
              : () => onSelected(slot),
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  final String label;
  final SlotState state;
  final VoidCallback? onTap;

  const _SlotTile({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final (Color background, Color foreground, Color border) = switch (state) {
      SlotState.selected => (colors.primary, colors.onPrimary, colors.primary),
      SlotState.available => (
          colors.surface,
          colors.onSurface,
          colors.outlineVariant,
        ),
      // Booked and past both read as unavailable, but only booked is worth
      // striking through — a past slot was never offered, it simply expired.
      SlotState.booked => (
          colors.surfaceContainerHigh,
          colors.onSurfaceVariant,
          Colors.transparent,
        ),
      SlotState.past => (
          colors.surfaceContainerLow,
          colors.outline,
          Colors.transparent,
        ),
    };

    return Semantics(
      button: state == SlotState.available || state == SlotState.selected,
      enabled: onTap != null,
      label: '$label, ${_semanticLabel(state)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: foreground,
              decoration: state == SlotState.booked
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: foreground,
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(SlotState state) {
    return switch (state) {
      SlotState.available => 'available',
      SlotState.selected => 'selected',
      SlotState.booked => 'already booked',
      SlotState.past => 'no longer available',
    };
  }
}

/// Explains the grid's colours.
///
/// Without this, a greyed tile is ambiguous — users read it as either "booked"
/// or "broken". Three swatches remove the guesswork.
class SlotLegend extends StatelessWidget {
  const SlotLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        _LegendItem(
          color: colors.surface,
          border: colors.outlineVariant,
          label: 'Available',
        ),
        AppSpacing.hGapLg,
        _LegendItem(
          color: colors.primary,
          border: colors.primary,
          label: 'Selected',
        ),
        AppSpacing.hGapLg,
        _LegendItem(
          color: colors.surfaceContainerHigh,
          border: Colors.transparent,
          label: 'Taken',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;

  const _LegendItem({
    required this.color,
    required this.border,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: border),
          ),
        ),
        AppSpacing.hGapXs,
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
