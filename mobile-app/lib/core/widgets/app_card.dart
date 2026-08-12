import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A surface panel.
///
/// [Card] already picks up the shape and border from `cardTheme`; this adds the
/// two things every call site was re-implementing — an optional tap target with
/// a correctly clipped ripple, and consistent internal padding.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// Draws the border in the brand colour — used to mark a selected item.
  final bool isHighlighted;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.isHighlighted = false,
  });

  /// A card whose child manages its own padding (an image that must bleed to
  /// the card's edges, for instance).
  const AppCard.bare({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.isHighlighted = false,
  }) : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(
          color: isHighlighted ? colors.primary : colors.outlineVariant,
          width: isHighlighted ? 1.6 : 1,
        ),
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          // InkWell inside the Card (rather than around it) so the ripple is
          // clipped by the card's rounded corners.
          : InkWell(
              onTap: onTap,
              borderRadius: AppRadius.lgAll,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}
