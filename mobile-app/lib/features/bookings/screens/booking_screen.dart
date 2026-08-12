import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../models/booking_model.dart';
import '../../../models/venue_model.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends StatefulWidget {
  final VenueModel venue;

  const BookingScreen({super.key, required this.venue});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const List<String> _allSlots = <String>[
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00',
  ];

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<BookingModel> _bookedSlots = <BookingModel>[];
  bool _isLoadingAvailability = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchAvailability();
    });
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoadingAvailability = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final List<BookingModel> availability = await context
          .read<BookingProvider>()
          .getVenueAvailability(widget.venue.id);
      if (!mounted) return;
      setState(() {
        _bookedSlots = availability;
        _isLoadingAvailability = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAvailability = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load availability: ${e.message}')),
      );
    }
  }

  bool _isSlotBooked(String slot) {
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _bookedSlots.any(
      (BookingModel b) => b.date == dateStr && b.startTime == slot,
    );
  }

  /// Slots earlier than now are not bookable on today's date.
  bool _isSlotPast(String slot) {
    final DateTime now = DateTime.now();
    if (!DateUtils.isSameDay(_selectedDate, now)) return false;
    final int hour = int.parse(slot.split(':')[0]);
    return hour <= now.hour;
  }

  String _endTimeFor(String startTime) {
    final int hour = int.parse(startTime.split(':')[0]);
    return '${(hour + 1).toString().padLeft(2, '0')}:00';
  }

  Future<void> _handleBooking() async {
    final String? slot = _selectedSlot;
    if (slot == null || _isSubmitting) return;

    // Captured before the first await so nothing reaches through the async gap.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BookingProvider bookingProvider = context.read<BookingProvider>();
    final PaymentProvider paymentProvider = context.read<PaymentProvider>();
    final GoRouter router = GoRouter.of(context);

    setState(() => _isSubmitting = true);

    BookingModel booking;
    try {
      booking = await bookingProvider.bookVenue(
        venueId: widget.venue.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: slot,
        endTime: _endTimeFor(slot),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // A conflicting slot means our availability snapshot is stale.
      await _fetchAvailability();
      return;
    }

    // The booking exists at this point; a payment failure is recoverable from
    // My Bookings, so it must not read as a failed booking.
    final PaymentResult result =
        await paymentProvider.makePayment(bookingId: booking.id);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      bookingProvider.markPaid(booking.id);
      await _showResultDialog(
        title: 'Booking confirmed',
        message: 'Your slot is booked and paid for.',
      );
      if (!mounted) return;
      router.goNamed(AppRoutes.myBookings);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isCancelled
              ? 'Booking saved as unpaid. You can pay from My Bookings.'
              : '${result.message} Your booking is saved as unpaid.',
        ),
        action: SnackBarAction(
          label: 'My bookings',
          onPressed: () => router.goNamed(AppRoutes.myBookings),
        ),
      ),
    );
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _selectedSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = _isSubmitting ||
        context.watch<BookingProvider>().isLoading ||
        context.watch<PaymentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a slot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(
            AppRoutes.venueDetails,
            pathParameters: <String, String>{'venueId': widget.venue.id},
            extra: widget.venue,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Date', style: theme.textTheme.titleMedium),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available slots',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Expanded(
            child: _isLoadingAvailability
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _allSlots.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String slot = _allSlots[index];
                      final bool unavailable =
                          _isSlotBooked(slot) || _isSlotPast(slot);
                      final bool selected = _selectedSlot == slot;

                      return _SlotTile(
                        label: slot,
                        unavailable: unavailable,
                        selected: selected,
                        onTap: unavailable || busy
                            ? null
                            : () => setState(() => _selectedSlot = slot),
                      );
                    },
                  ),
          ),
          _buildSummaryBar(theme, busy),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme, bool busy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Total (1 hour)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                Text(
                  '\$${widget.venue.pricePerHour.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: (_selectedSlot == null || busy) ? null : _handleBooking,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Book & pay'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One time slot in the grid. Booked, past, selected and available each read
/// differently rather than only booked-vs-not.
class _SlotTile extends StatelessWidget {
  final String label;
  final bool unavailable;
  final bool selected;
  final VoidCallback? onTap;

  const _SlotTile({
    required this.label,
    required this.unavailable,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color background = unavailable
        ? colors.surfaceContainerHighest
        : selected
            ? colors.primary
            : Colors.transparent;
    final Color foreground = unavailable
        ? colors.outline
        : selected
            ? colors.onPrimary
            : colors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: unavailable ? Colors.transparent : colors.primary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            decoration: unavailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
