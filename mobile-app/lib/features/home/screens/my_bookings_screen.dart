import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/venue_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingProvider.error != null
              ? Center(child: Text('Error: ${bookingProvider.error}'))
              : bookingProvider.myBookings.isEmpty
                  ? const Center(child: Text('No bookings yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookingProvider.myBookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookingProvider.myBookings[index];
                        final venue = booking.venue as VenueModel;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Venue Image Thumbnail
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[200],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: venue.images.isNotEmpty
                                      ? Image.network(venue.images[0], fit: BoxFit.cover)
                                      : const Icon(Icons.image),
                                ),
                                const SizedBox(width: 16),
                                
                                // Booking Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        venue.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        booking.date,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '${booking.startTime} - ${booking.endTime}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status & Price
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        booking.status.toUpperCase(),
                                        style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${booking.price}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
