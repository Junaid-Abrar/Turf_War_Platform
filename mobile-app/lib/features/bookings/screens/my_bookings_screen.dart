import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/booking_model.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/booking_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  /// The booking currently being paid, so only that card shows a spinner. The
  /// screen used to read `PaymentProvider.isLoading` on every card at once,
  /// which spun all of them during a single payment.
  String? _payingBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingProvider>().fetchMyBookings();
    });
  }

  Future<void> _pay(BookingModel booking) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BookingProvider bookingProvider = context.read<BookingProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;

    setState(() => _payingBookingId = booking.id);
    final PaymentResult result = await context
        .read<PaymentProvider>()
        .makePayment(bookingId: booking.id);

    if (!mounted) return;
    setState(() => _payingBookingId = null);

    if (result.isSuccess) {
      bookingProvider.markPaid(booking.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment received. You are all set.')),
      );
      await bookingProvider.fetchMyBookings();
      return;
    }

    // A deliberate dismissal of the payment sheet is not an error worth
    // shouting about.
    if (result.isCancelled) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Payment failed'),
        backgroundColor: colors.error,
      ),
    );
  }

  Future<void> _cancel(BookingModel booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Your ${booking.startTime} slot on '
          '${_formatDate(booking.date)} will be released for others to book.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookingProvider>().cancelBooking(booking.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingProvider provider = context.watch<BookingProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => context.goNamed(AppRoutes.home),
          ),
          bottom: TabBar(
            tabs: <Widget>[
              _CountedTab(
                label: 'Upcoming',
                count: provider.upcomingBookings.length,
              ),
              _CountedTab(label: 'Past', count: provider.pastBookings.length),
              _CountedTab(
                label: 'Cancelled',
                count: provider.cancelledBookings.length,
              ),
            ],
          ),
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(BookingProvider provider) {
    if (provider.isLoading && provider.myBookings.isEmpty) {
      return const BookingListSkeleton();
    }

    if (provider.error != null && provider.myBookings.isEmpty) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<BookingProvider>().fetchMyBookings(),
      );
    }

    return TabBarView(
      children: <Widget>[
        _buildList(
          provider.upcomingBookings,
          title: 'Nothing booked yet',
          message: 'Find a pitch and grab a slot — it takes about a minute.',
        ),
        _buildList(
          provider.pastBookings,
          title: 'No past bookings',
          message: 'Slots you have already played show up here.',
        ),
        _buildList(
          provider.cancelledBookings,
          title: 'No cancellations',
          message: 'Bookings you cancel are kept here for your records.',
        ),
      ],
    );
  }

  Widget _buildList(
    List<BookingModel> bookings, {
    required String title,
    required String message,
  }) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: title,
        message: message,
        action: AppButton(
          label: 'Browse venues',
          onPressed: () => context.goNamed(AppRoutes.home),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BookingProvider>().fetchMyBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: bookings.length,
        itemBuilder: (BuildContext context, int index) {
          final BookingModel booking = bookings[index];
          return _BookingCard(
            booking: booking,
            isPaying: _payingBookingId == booking.id,
            onPay: () => _pay(booking),
            onCancel: () => _cancel(booking),
            onOpenVenue: () => context.goNamed(
              AppRoutes.venueDetails,
              pathParameters: <String, String>{'venueId': booking.venueId},
            ),
          );
        },
      ),
    );
  }
}

/// The API returns dates as `yyyy-MM-dd` strings; anything unparseable is shown
/// verbatim rather than swallowed.
String _formatDate(String raw) {
  final DateTime? date = DateTime.tryParse(raw);
  return date == null ? raw : DateFormat('EEE, d MMM').format(date);
}

/// Tab label with the number of bookings in that bucket.
class _CountedTab extends StatelessWidget {
  final String label;
  final int count;

  const _CountedTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label),
          if (count > 0) ...<Widget>[
            AppSpacing.hGapXs,
            Text(
              '($count)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPaying;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onOpenVenue;

  const _BookingCard({
    required this.booking,
    required this.isPaying,
    required this.onPay,
    required this.onCancel,
    required this.onOpenVenue,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // `venue` is populated by GET /bookings/my, but the model no longer assumes
    // it — a booking created this session holds only the id.
    final String? image = booking.venue?.primaryImage;
    final bool canPay = !booking.isPaid && !booking.isCancelled;
    final bool canCancel = !booking.isCancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onOpenVenue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: AppNetworkImage(
                    url: image,
                    width: 76,
                    height: 76,
                    fallbackIconSize: 28,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      AppSpacing.gapXs,
                      _IconLine(
                        icon: Icons.event_outlined,
                        text: _formatDate(booking.date),
                      ),
                      AppSpacing.gapXxs,
                      _IconLine(
                        icon: Icons.schedule,
                        text: '${booking.startTime} – ${booking.endTime}',
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    StatusBadge.forBookingStatus(booking.status),
                    AppSpacing.gapSm,
                    Text(
                      '\$${booking.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (!booking.isCancelled) ...<Widget>[
                      AppSpacing.gapXs,
                      StatusBadge.forPaymentStatus(booking.paymentStatus),
                    ],
                  ],
                ),
              ],
            ),
            if (canPay || canCancel) ...<Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(),
              ),
              Row(
                children: <Widget>[
                  if (canCancel)
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: isPaying ? null : onCancel,
                      ),
                    ),
                  if (canPay && canCancel) AppSpacing.hGapMd,
                  if (canPay)
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Pay \$${booking.price.toStringAsFixed(2)}',
                        expand: true,
                        isLoading: isPaying,
                        onPressed: onPay,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        AppSpacing.hGapXs,
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
