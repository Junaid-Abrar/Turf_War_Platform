import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Wraps content in the app's shimmer treatment.
///
/// Skeletons replace the bare [CircularProgressIndicator] the list screens used
/// to show. The point is not decoration: a skeleton in the shape of the content
/// tells the user what is coming and keeps the layout from jumping when data
/// lands, whereas a centred spinner does neither.
class ShimmerLoader extends StatelessWidget {
  final Widget child;

  const ShimmerLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;
    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: child,
    );
  }
}

/// A single grey block used to compose skeletons.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.smAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer paints its gradient over whatever it wraps, so the colour
        // here only needs to be opaque.
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Skeleton matching the layout of a `VenueCard`.
class VenueCardSkeleton extends StatelessWidget {
  const VenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgAll,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBox(height: 168, borderRadius: AppRadius.lgAll),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 180, height: 16),
                  AppSpacing.gapSm,
                  ShimmerBox(width: 120, height: 12),
                  AppSpacing.gapSm,
                  ShimmerBox(width: 220, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of [VenueCardSkeleton]s, shown while the first page of venues loads.
class VenueListSkeleton extends StatelessWidget {
  final int itemCount;

  const VenueListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      // Nothing to scroll to yet, and scrolling a skeleton looks broken.
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const VenueCardSkeleton(),
    );
  }
}

/// Skeleton matching the layout of a booking card.
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgAll,
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBox(width: 76, height: 76, borderRadius: AppRadius.mdAll),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 140, height: 15),
                  AppSpacing.gapSm,
                  ShimmerBox(width: 90, height: 12),
                  AppSpacing.gapSm,
                  ShimmerBox(width: 110, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of [BookingCardSkeleton]s for the My Bookings tabs.
class BookingListSkeleton extends StatelessWidget {
  final int itemCount;

  const BookingListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const BookingCardSkeleton(),
    );
  }
}
