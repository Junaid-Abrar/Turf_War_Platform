import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A read-only star rating.
///
/// Renders halves rather than rounding, so 4.5 does not read as either 4 or 5.
/// The star colour comes from [AppSemanticColors.rating]; call sites used to
/// hardcode `Colors.amber`, which is too light to pass contrast on a white card.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  /// Appends the numeric value after the stars.
  final bool showValue;

  /// Optional review count, rendered as `(12)` after the value.
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = false,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color starColor = context.semanticColors.rating;
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Icon(
            _iconFor(i),
            size: size,
            color: i <= rating.ceil() ? starColor : theme.colorScheme.outline,
          ),
        if (showValue) ...<Widget>[
          AppSpacing.hGapXs,
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'New',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (reviewCount != null) ...<Widget>[
          AppSpacing.hGapXs,
          Text(
            '($reviewCount)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(int position) {
    if (rating >= position) return Icons.star_rounded;
    // Half-filled when the rating lands anywhere inside this star.
    if (rating > position - 1) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}

/// The distribution bar chart shown above a venue's review list — one row per
/// star value with the share of reviews that gave it.
class RatingDistribution extends StatelessWidget {
  /// Ratings of every review, unsorted.
  final List<double> ratings;

  const RatingDistribution({super.key, required this.ratings});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color starColor = context.semanticColors.rating;

    if (ratings.isEmpty) return const SizedBox.shrink();

    // counts[0] holds 1-star, counts[4] holds 5-star.
    final List<int> counts = List<int>.filled(5, 0);
    for (final double rating in ratings) {
      final int index = rating.round().clamp(1, 5) - 1;
      counts[index]++;
    }
    final double average =
        ratings.reduce((double a, double b) => a + b) / ratings.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            Text(
              average.toStringAsFixed(1),
              style: theme.textTheme.displaySmall,
            ),
            RatingStars(rating: average, size: 14),
            AppSpacing.gapXs,
            Text(
              '${ratings.length} ${ratings.length == 1 ? 'review' : 'reviews'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.hGapLg,
        Expanded(
          child: Column(
            children: <Widget>[
              // Highest rating first, matching how review UIs conventionally
              // read top-to-bottom.
              for (int star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$star',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      AppSpacing.hGapXs,
                      Icon(Icons.star_rounded, size: 12, color: starColor),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: counts[star - 1] / ratings.length,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(starColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
