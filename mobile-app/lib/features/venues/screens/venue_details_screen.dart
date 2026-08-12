import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../models/review_model.dart';
import '../../../models/venue_model.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/venue_provider.dart';
import '../services/venue_service.dart';

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

  Future<void> _showAddReviewDialog() async {
    final TextEditingController commentController = TextEditingController();
    double rating = 5;

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Write a review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<double>(
                    initialValue: rating,
                    decoration: const InputDecoration(labelText: 'Rating'),
                    items: List<int>.generate(5, (int i) => i + 1)
                        .map(
                          (int value) => DropdownMenuItem<double>(
                            value: value.toDouble(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('$value '),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (double? value) {
                      if (value != null) {
                        setDialogState(() => rating = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true || !mounted) {
      commentController.dispose();
      return;
    }

    final String comment = commentController.text;
    commentController.dispose();

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await context
          .read<VenueProvider>()
          .addReview(widget.venueId, rating, comment);
      await _loadReviews();
      messenger.showSnackBar(
        const SnackBar(content: Text('Review added')),
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed(AppRoutes.home),
          ),
        ),
        body: _isLoadingVenue
            ? const Center(child: CircularProgressIndicator())
            : ErrorState(
                message: _error ?? 'Venue not found.',
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
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.goNamed(AppRoutes.home),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                venue.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: <Shadow>[Shadow(blurRadius: 10)],
                ),
              ),
              background: venue.primaryImage != null
                  ? Image.network(
                      venue.primaryImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(theme),
                    )
                  : _imageFallback(theme),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              venue.name,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venue.location,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  venue.averageRating > 0
                                      ? venue.averageRating.toStringAsFixed(1)
                                      : 'New',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${_reviews.length} reviews)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${venue.pricePerHour.toStringAsFixed(0)}/hr',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('About', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    venue.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  if (venue.amenities.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    Text('Amenities', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: venue.amenities
                          .map(
                            (String amenity) => Chip(
                              label: Text(amenity),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Text('Reviews', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      if (!isOwner)
                        TextButton.icon(
                          onPressed: _showAddReviewDialog,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Write review'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Text(
                      'No reviews yet. Be the first!',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    )
                  else
                    ..._reviews.map(
                      (ReviewModel review) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(review.userName[0].toUpperCase()),
                          ),
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  review.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              Text(review.rating.toStringAsFixed(1)),
                            ],
                          ),
                          subtitle: Text(review.comment),
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isOwner
          ? _ownerBanner(theme)
          : _bookingBar(context, theme, venue),
    );
  }

  Widget _imageFallback(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.sports_soccer,
        size: 96,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _ownerBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.store, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            'This is your venue',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingBar(BuildContext context, ThemeData theme, VenueModel venue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.goNamed(
                  AppRoutes.chat,
                  pathParameters: <String, String>{
                    'venueId': venue.id,
                    'receiverId': venue.ownerId,
                  },
                  queryParameters: <String, String>{'name': 'Venue owner'},
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: () => context.goNamed(
                  AppRoutes.booking,
                  pathParameters: <String, String>{'venueId': venue.id},
                  extra: venue,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Book now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
