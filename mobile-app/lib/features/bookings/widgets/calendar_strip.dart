import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';

/// A horizontal run of upcoming days.
///
/// Replaces the "Change" button that opened a full [showDatePicker] for what is
/// almost always today or tomorrow. The picker is still reachable for dates
/// further out — see the trailing button the booking screen adds beside this.
class CalendarStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  /// How many days forward to offer. Matches the 30-day window the date picker
  /// allows, so the two agree on what is bookable.
  final int dayCount;

  const CalendarStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.dayCount = 14,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: dayCount,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = today.add(Duration(days: index));
          return _DayTile(
            day: day,
            isSelected: DateUtils.isSameDay(day, selected),
            isToday: index == 0,
            onTap: () => onSelected(day),
          );
        },
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayTile({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color background =
        isSelected ? colors.primary : colors.surfaceContainerLow;
    final Color foreground =
        isSelected ? colors.onPrimary : colors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              // 'Today' rather than the weekday for the first tile: it is the
              // default selection and the label users look for.
              isToday ? 'Today' : DateFormat.E().format(day),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? foreground.withValues(alpha: 0.9)
                    : colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              DateFormat.d().format(day),
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
            Text(
              DateFormat.MMM().format(day),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? foreground.withValues(alpha: 0.9)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
