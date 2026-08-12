import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/booking_model.dart';
import '../../../models/venue_model.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/time_slot_grid.dart';

class BookingScreen extends StatefulWidget {
  final VenueModel venue;

  const BookingScreen({super.key, required this.venue});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const List<String> _allSlots = <String>[
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', //
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', //
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00', //
  ];

  /// How far ahead a slot can be booked. Shared by the strip and the picker so
  /// they cannot disagree about what is reachable.
  static const int _bookingWindowDays = 30;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
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

  SlotState _slotState(String slot) {
    if (_selectedSlot == slot) return SlotState.selected;

    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final bool isBooked = _bookedSlots.any(
      (BookingModel b) => b.date == dateStr && b.startTime == slot,
    );
    if (isBooked) return SlotState.booked;

    // Slots earlier than now are not bookable on today's date.
    final DateTime now = DateTime.now();
    if (DateUtils.isSameDay(_selectedDate, now) &&
        int.parse(slot.split(':')[0]) <= now.hour) {
      return SlotState.past;
    }

    return SlotState.available;
  }

  String _endTimeFor(String startTime) {
    final int hour = int.parse(startTime.split(':')[0]);
    return '${(hour + 1).toString().padLeft(2, '0')}:00';
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // The slot numbers repeat across days but their availability does not,
      // so a selection cannot survive a date change.
      _selectedSlot = null;
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(const Duration(days: _bookingWindowDays)),
    );
    if (picked == null || !mounted) return;
    _onDateSelected(DateUtils.dateOnly(picked));
  }

  Future<void> _handleBooking() async {
    final String? slot = _selectedSlot;
    if (slot == null || _isSubmitting) return;

    // Captured before the first await so nothing reaches through the async gap.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BookingProvider bookingProvider = context.read<BookingProvider>();
    final PaymentProvider paymentProvider = context.read<PaymentProvider>();
    final GoRouter router = GoRouter.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

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
        SnackBar(content: Text(e.message), backgroundColor: colors.error),
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
      await _showConfirmation(booking);
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

  Future<void> _showConfirmation(BookingModel booking) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        return AlertDialog(
          icon: Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          title: const Text('You are booked'),
          content: Text(
            '${widget.venue.name}\n'
            '${DateFormat('EEEE, d MMMM').format(_selectedDate)}\n'
            '${booking.startTime} – ${booking.endTime}',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('View my bookings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = _isSubmitting ||
        context.watch<BookingProvider>().isLoading ||
        context.watch<PaymentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a slot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.goNamed(
            AppRoutes.venueDetails,
            pathParameters: <String, String>{'venueId': widget.venue.id},
            extra: widget.venue,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pick another date',
            onPressed: busy ? null : _pickDate,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              widget.venue.name,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CalendarStrip(
            selected: _selectedDate,
            onSelected: busy ? (_) {} : _onDateSelected,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM').format(_selectedDate),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SlotLegend(),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingAvailability
                ? const _SlotGridSkeleton()
                : TimeSlotGrid(
                    slots: _allSlots,
                    stateFor: _slotState,
                    enabled: !busy,
                    onSelected: (String slot) =>
                        setState(() => _selectedSlot = slot),
                  ),
          ),
          _SummaryBar(
            venue: widget.venue,
            selectedSlot: _selectedSlot,
            endTime: _selectedSlot == null ? null : _endTimeFor(_selectedSlot!),
            busy: busy,
            onConfirm: _handleBooking,
          ),
        ],
      ),
    );
  }
}

/// Skeleton in the shape of the slot grid, so the layout does not jump when
/// availability lands.
class _SlotGridSkeleton extends StatelessWidget {
  const _SlotGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => const ShimmerBox(
          height: 48,
          borderRadius: AppRadius.mdAll,
        ),
      ),
    );
  }
}

/// The pinned price breakdown and confirm action.
class _SummaryBar extends StatelessWidget {
  final VenueModel venue;
  final String? selectedSlot;
  final String? endTime;
  final bool busy;
  final VoidCallback onConfirm;

  const _SummaryBar({
    required this.venue,
    required this.selectedSlot,
    required this.endTime,
    required this.busy,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSlot = selectedSlot != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The breakdown appears only once a slot is chosen; before that
              // there is nothing to total and a "$0.00" would be misleading.
              AnimatedSize(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                child: hasSlot
                    ? _PriceBreakdown(
                        venue: venue,
                        startTime: selectedSlot!,
                        endTime: endTime!,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (hasSlot) AppSpacing.gapMd,
              AppButton(
                label: hasSlot ? 'Confirm and pay' : 'Select a time',
                expand: true,
                isLoading: busy,
                onPressed: hasSlot ? onConfirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Line-by-line cost of the selected slot.
///
/// The total shown here is the client's arithmetic; the backend recomputes it
/// from the venue's rate when the booking is created (a Phase 1 fix — price
/// used to be sent from the client). They agree for a one-hour slot, and the
/// server's figure is what is charged.
class _PriceBreakdown extends StatelessWidget {
  final VenueModel venue;
  final String startTime;
  final String endTime;

  const _PriceBreakdown({
    required this.venue,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const int hours = 1;
    final double total = venue.pricePerHour * hours;

    return Column(
      children: <Widget>[
        _Line(
          label: '$startTime – $endTime',
          value: '$hours hour',
          isMuted: true,
        ),
        AppSpacing.gapXs,
        _Line(
          label: '\$${venue.pricePerHour.toStringAsFixed(2)} × $hours hour',
          value: '\$${total.toStringAsFixed(2)}',
          isMuted: true,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Total', style: theme.textTheme.titleMedium),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;

  const _Line({
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: isMuted ? theme.colorScheme.onSurfaceVariant : null,
    );

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
