import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/venue_model.dart';
import 'amenity_icons.dart';

/// Tag shared with the detail screen's header image so the photo flies between
/// the two rather than cutting. Built from the venue id so two cards never
/// collide — duplicate hero tags on one route throw at runtime.
String venueHeroTag(String venueId) => 'venue-image-$venueId';

/// A venue in the home list.
class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard.bare(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Hero(
                  tag: venueHeroTag(venue.id),
                  child: AppNetworkImage(
                    url: venue.primaryImage,
                    height: 168,
                    width: double.infinity,
                    fallbackIconSize: 48,
                  ),
                ),
                // Price sits on the image so the eye finds it in the same place
                // on every card, regardless of how long the venue name runs.
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _PriceTag(pricePerHour: venue.pricePerHour),
                ),
                if (venue.averageRating > 0)
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: _RatingPill(rating: venue.averageRating),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacing.gapXs,
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.hGapXs,
                      Expanded(
                        child: Text(
                          venue.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (venue.amenities.isNotEmpty) ...<Widget>[
                    AppSpacing.gapMd,
                    // Icons rather than text chips: four amenities fit on one
                    // line at any text scale, where the chips used to wrap.
                    Row(
                      children: <Widget>[
                        for (final String amenity in venue.amenities.take(4))
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: Tooltip(
                              message: amenity,
                              child: Icon(
                                iconForAmenity(amenity),
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (venue.amenities.length > 4)
                          Text(
                            '+${venue.amenities.length - 4}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The price badge overlaid on a card's image.
class _PriceTag extends StatelessWidget {
  final double pricePerHour;

  const _PriceTag({required this.pricePerHour});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.smAll,
      ),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '\$${pricePerHour.toStringAsFixed(0)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(
              text: '/hr',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rating badge overlaid on a card's image.
class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.pillAll,
      ),
      // A single star plus the number, not the full five-star row: at this size
      // five glyphs read as noise, and the exact value is what a browsing user
      // is comparing between cards.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.star_rounded,
            size: 14,
            color: context.semanticColors.rating,
          ),
          AppSpacing.hGapXs,
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
