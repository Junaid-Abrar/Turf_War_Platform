import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../models/booking_model.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/booking_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
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

    final PaymentResult result = await context
        .read<PaymentProvider>()
        .makePayment(bookingId: booking.id);

    if (!mounted) return;

    if (result.isSuccess) {
      bookingProvider.markPaid(booking.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
      await bookingProvider.fetchMyBookings();
      return;
    }

    if (result.isCancelled) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Payment failed'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _cancel(BookingModel booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'This will release your ${booking.startTime} slot on ${booking.date}.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
        const SnackBar(content: Text('Booking cancelled')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
            onPressed: () => context.goNamed(AppRoutes.home),
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(BookingProvider provider) {
    if (provider.isLoading && provider.myBookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<BookingProvider>().fetchMyBookings(),
      );
    }

    return TabBarView(
      children: <Widget>[
        _buildList(provider.upcomingBookings, 'No upcoming bookings'),
        _buildList(provider.pastBookings, 'No past bookings'),
        _buildList(provider.cancelledBookings, 'No cancelled bookings'),
      ],
    );
  }

  Widget _buildList(List<BookingModel> bookings, String emptyTitle) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: emptyTitle,
        message: 'Book a turf from the home screen to see it here.',
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoutes.home),
          child: const Text('Browse venues'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BookingProvider>().fetchMyBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (BuildContext context, int index) {
          return _BookingCard(
            booking: bookings[index],
            isPaying: context.watch<PaymentProvider>().isLoading,
            onPay: () => _pay(bookings[index]),
            onCancel: () => _cancel(bookings[index]),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPaying;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.isPaying,
    required this.onPay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // `venue` is populated by GET /bookings/my, but the model no longer assumes
    // it — a booking created this session holds only the id.
    final String? image = booking.venue?.primaryImage;
    final bool canPay = !booking.isPaid && !booking.isCancelled;
    final bool canCancel = !booking.isCancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: image != null
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports_soccer),
                        )
                      : const Icon(Icons.sports_soccer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.date,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      Text(
                        '${booking.startTime} – ${booking.endTime}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    _StatusBadge(booking: booking),
                    const SizedBox(height: 8),
                    Text(
                      '\$${booking.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            if (canPay || canCancel) ...<Widget>[
              const Divider(height: 24),
              Row(
                children: <Widget>[
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (canPay && canCancel) const SizedBox(width: 12),
                  if (canPay)
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isPaying ? null : onPay,
                        child: isPaying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Pay now'),
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

class _StatusBadge extends StatelessWidget {
  final BookingModel booking;

  const _StatusBadge({required this.booking});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color color = booking.isCancelled
        ? colors.error
        : booking.isConfirmed
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        booking.status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
