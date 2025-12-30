import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/venue_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/payment_provider.dart'; // Add

class BookingScreen extends StatefulWidget {
  final VenueModel venue;

  const BookingScreen({super.key, required this.venue});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoadingAvailability = false;

  final List<String> _allSlots = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoadingAvailability = true);
    try {
      final availability = await Provider.of<BookingProvider>(context, listen: false)
          .getVenueAvailability(widget.venue.id);
      if (!mounted) return;
      setState(() {
        _bookedSlots = availability;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAvailability = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading availability: $e')),
      );
    }
  }

  bool _isSlotBooked(String slot) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _bookedSlots.any((b) => b['date'] == dateStr && b['startTime'] == slot);
  }

  void _handleBooking() async {
    if (_selectedSlot == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startTime = _selectedSlot!;
      
      // Calculate end time (1 hour later for simplicity)
      final hour = int.parse(startTime.split(':')[0]);
      final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';

      final booking = await Provider.of<BookingProvider>(context, listen: false).bookVenue(
        venueId: widget.venue.id,
        date: dateStr,
        startTime: startTime,
        endTime: endTime,
        price: widget.venue.pricePerHour,
      );

      if (mounted) {
        // Proceed to Payment
        try {
          await Provider.of<PaymentProvider>(context, listen: false).makePayment(
            context: context,
            bookingId: booking.id,
          );
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Success'),
                content: const Text('Your booking has been confirmed and paid!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Pop dialog
                      Navigator.of(context).pop(); // Pop BookingScreen
                    },
                    child: const Text('OK'),
                  )
                ],
              ),
            );
          }
        } catch (paymentError) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Payment failed, but booking is saved. Please pay from "My Bookings": $paymentError')),
             );
             Navigator.of(context).pop();
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context); // Add

    return Scaffold(
      appBar: AppBar(title: const Text('Select Slot')),
      body: Column(
        children: [
          // Date Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedSlot = null; // Reset slot when date changes
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Available Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // Slots Grid
          Expanded(
            child: _isLoadingAvailability 
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _allSlots[index];
                    final isBooked = _isSlotBooked(slot);
                    final isSelected = _selectedSlot == slot;

                    return GestureDetector(
                      onTap: isBooked ? null : () {
                        setState(() => _selectedSlot = slot);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked 
                            ? Colors.grey[200] 
                            : isSelected ? Colors.green : Colors.white,
                          border: Border.all(
                            color: isBooked ? Colors.transparent : Colors.green,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot,
                          style: TextStyle(
                            color: isBooked 
                              ? Colors.grey 
                              : isSelected ? Colors.white : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(color: Colors.grey)),
                    Text('\$${widget.venue.pricePerHour}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  onPressed: (_selectedSlot == null || bookingProvider.isLoading || paymentProvider.isLoading) ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: (bookingProvider.isLoading || paymentProvider.isLoading)
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Book & Pay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
