import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/review_model.dart';
import '../../../models/venue_model.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/venue_provider.dart';
import '../services/venue_service.dart';
import '../widgets/amenity_icons.dart';
import '../widgets/review_dialog.dart';
import '../widgets/venue_card.dart';
import '../widgets/venue_image_carousel.dart';

/// Venue detail page.
///
/// Addressed by id rather than by object so the route is deep-linkable.
/// [initialVenue] is supplied when navigating from the list, letting the page
/// paint immediately; arriving cold (deep link, restart) fetches by id instead.
class VenueDetailsScreen extends StatefulWidget {
  final String venueId;
  final VenueModel? initialVenue;

  const VenueDetailsScreen({
    super.key,
    required this.venueId,
    this.initialVenue,
  });

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  VenueModel? _venue;
  List<ReviewModel> _reviews = <ReviewModel>[];
  bool _isLoadingVenue = false;
  bool _isLoadingReviews = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _venue = widget.initialVenue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_venue == null) _loadVenue();
      _loadReviews();
    });
  }

  Future<void> _loadVenue() async {
    setState(() {
      _isLoadingVenue = true;
      _error = null;
    });
    try {
      final VenueModel venue =
          await context.read<VenueService>().getVenue(widget.venueId);
      if (!mounted) return;
      setState(() {
        _venue = venue;
        _isLoadingVenue = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoadingVenue = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final List<ReviewModel> reviews =
          await context.read<VenueProvider>().getReviews(widget.venueId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _addReview() async {
    final ReviewDraft? draft = await showReviewDialog(context);
    if (draft == null || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await context
          .read<VenueProvider>()
          .addReview(widget.venueId, draft.rating, draft.comment);
      await _loadReviews();
      // Refetches the venue too: adding a review changes its average rating,
      // which is shown in the header.
      await _loadVenue();
      messenger.showSnackBar(
        const SnackBar(content: Text('Thanks — your review is live.')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final VenueModel? venue = _venue;

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: _isLoadingVenue
            ? const Center(child: CircularProgressIndicator())
            : ErrorState(
                message: _error ?? 'This venue could not be found.',
                onRetry: _loadVenue,
              ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final String? currentUserId = context.watch<UserProvider>().user?.id;
    final bool isOwner =
        currentUserId != null && currentUserId == venue.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: const _BackButton(),
            // Transparent until collapsed, at which point the title appears
            // over the app bar's own surface rather than over the photo.
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 56,
                vertical: AppSpacing.md,
              ),
              title: Text(
                venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              background: VenueImageCarousel(
                images: venue.images,
                heroTag: venueHeroTag(venue.id),
              ),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                // Clears the pinned booking bar.
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Header(venue: venue, reviewCount: _reviews.length),
                  AppSpacing.gapXl,
                  const Divider(),
                  AppSpacing.gapXl,
                  const SectionHeader(title: 'About'),
                  AppSpacing.gapSm,
                  Text(
                    venue.description.isEmpty
                        ? 'The owner has not added a description yet.'
                        : venue.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (venue.amenities.isNotEmpty) ...<Widget>[
                    AppSpacing.gapXxl,
                    const SectionHeader(title: 'What this venue offers'),
                    AppSpacing.gapMd,
                    _AmenityGrid(amenities: venue.amenities),
                  ],
                  AppSpacing.gapXxl,
                  SectionHeader(
                    title: 'Reviews',
                    action: isOwner
                        ? null
                        : TextButton.icon(
                            onPressed: _addReview,
                            icon: const Icon(Icons.rate_review_outlined,
                                size: 18),
                            label: const Text('Write one'),
                          ),
                  ),
                  AppSpacing.gapMd,
                  _ReviewSection(
                    reviews: _reviews,
                    isLoading: _isLoadingReviews,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? _OwnerBanner(venue: venue)
          : _BookingBar(venue: venue),
    );
  }
}

/// Back button that survives a cold deep link.
///
/// `context.pop()` would throw when this screen is the first route in the
/// stack, which is exactly what happens on a deep link, so it falls back to
/// going home.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.home);
            }
          },
        ),
      ),
    );
  }
}

/// Name, location, rating and price block below the image.
class _Header extends StatelessWidget {
  final VenueModel venue;
  final int reviewCount;

  const _Header({required this.venue, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(venue.name, style: theme.textTheme.headlineMedium),
            ),
            AppSpacing.hGapMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '\$${venue.pricePerHour.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'per hour',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapSm,
        Row(
          children: <Widget>[
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.hGapXs,
            Expanded(
              child: Text(
                venue.location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        if (venue.averageRating > 0)
          RatingStars(
            rating: venue.averageRating,
            showValue: true,
            reviewCount: reviewCount,
          )
        else
          Text(
            'No ratings yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Amenities as a two-column icon list rather than the plain chips this screen
/// used to render — an icon per amenity is scannable without reading.
class _AmenityGrid extends StatelessWidget {
  final List<String> amenities;

  const _AmenityGrid({required this.amenities});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Wrap(
      runSpacing: AppSpacing.md,
      children: <Widget>[
        for (final String amenity in amenities)
          SizedBox(
            // Two per row, minus the spacing between them.
            width: (MediaQuery.sizeOf(context).width - AppSpacing.lg * 2) / 2,
            child: Row(
              children: <Widget>[
                Icon(
                  iconForAmenity(amenity),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    amenity,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The reviews list, with the rating distribution above it.
class _ReviewSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final bool isLoading;

  const _ReviewSection({required this.reviews, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (isLoading) {
      return const ShimmerLoader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBox(height: 72, borderRadius: AppRadius.mdAll),
            AppSpacing.gapMd,
            ShimmerBox(height: 72, borderRadius: AppRadius.mdAll),
          ],
        ),
      );
    }

    if (reviews.isEmpty) {
      return Text(
        'No reviews yet. Be the first to play here and say how it went.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RatingDistribution(
          ratings: reviews.map((ReviewModel r) => r.rating).toList(),
        ),
        AppSpacing.gapXl,
        for (final ReviewModel review in reviews) ...<Widget>[
          _ReviewTile(review: review),
          AppSpacing.gapMd,
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  // `userName` is never empty — the model substitutes
                  // 'Anonymous' for a deleted author — so this cannot throw.
                  review.userName[0].toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      review.userName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              RatingStars(rating: review.rating, size: 14),
            ],
          ),
          if (review.comment.isNotEmpty) ...<Widget>[
            AppSpacing.gapSm,
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Pinned bar with the chat and book actions.
class _BookingBar extends StatelessWidget {
  final VenueModel venue;

  const _BookingBar({required this.venue});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            // Chat is backed by Firestore, which isn't configured for the web
            // demo build (see AppConfig.demoMode) — hidden there rather than
            // left as a button that fails when tapped.
            if (!AppConfig.demoMode) ...<Widget>[
              IconButton(
                onPressed: () => context.goNamed(
                  AppRoutes.chat,
                  pathParameters: <String, String>{
                    'venueId': venue.id,
                    'receiverId': venue.ownerId,
                  },
                  queryParameters: <String, String>{'name': 'Venue owner'},
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Message the owner',
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
              AppSpacing.hGapMd,
            ],
            Expanded(
              child: AppButton(
                label: 'Check availability',
                expand: true,
                onPressed: () => context.goNamed(
                  AppRoutes.booking,
                  pathParameters: <String, String>{'venueId': venue.id},
                  extra: venue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the booking bar when the signed-in user owns this venue —
/// the backend rejects an owner booking their own venue, so the action is
/// removed rather than left to fail.
class _OwnerBanner extends StatelessWidget {
  final VenueModel venue;

  const _OwnerBanner({required this.venue});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: theme.colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.storefront_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                'This is your venue. Players book it from here.',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
