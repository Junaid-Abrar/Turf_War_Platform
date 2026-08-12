import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A sport shortcut on the home screen.
///
/// The backend has no sport field on a venue, so each category carries a
/// [searchTerm] that is folded into the same free-text query the search box
/// uses. That keeps this honest — it is a saved search, not a filter over data
/// the API does not have.
enum SportCategory {
  all('All', Icons.apps, ''),
  football('Football', Icons.sports_soccer, 'football'),
  cricket('Cricket', Icons.sports_cricket, 'cricket'),
  basketball('Basketball', Icons.sports_basketball, 'basketball'),
  tennis('Tennis', Icons.sports_tennis, 'tennis'),
  badminton('Badminton', Icons.sports_tennis, 'badminton');

  final String label;
  final IconData icon;
  final String searchTerm;

  const SportCategory(this.label, this.icon, this.searchTerm);
}

/// Horizontally scrolling category selector.
class SportCategoryRow extends StatelessWidget {
  final SportCategory selected;
  final ValueChanged<SportCategory> onSelected;

  const SportCategoryRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: SportCategory.values.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (BuildContext context, int index) {
          final SportCategory category = SportCategory.values[index];
          return _CategoryChip(
            category: category,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final SportCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color background =
        isSelected ? colors.primary : colors.surfaceContainerLow;
    final Color foreground =
        isSelected ? colors.onPrimary : colors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.pillAll,
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(category.icon, size: 16, color: foreground),
              AppSpacing.hGapSm,
              Text(
                category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
