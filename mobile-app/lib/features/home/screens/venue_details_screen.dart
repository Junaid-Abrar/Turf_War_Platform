import 'package:flutter/material.dart';
import '../../../models/venue_model.dart';
import 'booking_screen.dart'; // We will create this next

class VenueDetailsScreen extends StatelessWidget {
  final VenueModel venue;

  const VenueDetailsScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible AppBar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(venue.name, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 10)])),
              background: venue.images.isNotEmpty
                ? Image.network(venue.images[0], fit: BoxFit.cover)
                : Container(color: Colors.green, child: const Icon(Icons.sports_soccer, size: 100, color: Colors.white)),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venue.name, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(venue.location, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Text('\$${venue.pricePerHour}/hr', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(venue.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: venue.amenities.map((a) => Chip(
                      label: Text(a),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(venue: venue)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Book Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
