import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/venue_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'add_venue_screen.dart';
import 'venue_details_screen.dart'; // Import Details Screen
import 'my_bookings_screen.dart'; // Import My Bookings Screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<VenueProvider>(context, listen: false).fetchVenues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final venueProvider = Provider.of<VenueProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf War'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            },
            tooltip: 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVenueScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name ?? "User"}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Find your turf',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Venue List
          Expanded(
            child: venueProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : venueProvider.error != null
                    ? Center(child: Text('Error: ${venueProvider.error}'))
                    : venueProvider.venues.isEmpty
                        ? const Center(child: Text('No venues found'))
                        : ListView.builder(
                            itemCount: venueProvider.venues.length,
                            itemBuilder: (context, index) {
                              final venue = venueProvider.venues[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => VenueDetailsScreen(venue: venue))
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: venue.images.isNotEmpty
                                          ? Image.network(
                                              venue.images[0], 
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                                            )
                                          : const Center(
                                              child: Icon(Icons.sports_soccer, size: 50, color: Colors.grey),
                                            ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  venue.name,
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  '\$${venue.pricePerHour}/hr',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(venue.location, style: const TextStyle(color: Colors.grey)),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: venue.amenities.map((a) => 
                                                Chip(label: Text(a, style: const TextStyle(fontSize: 10)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,)
                                              ).toList(),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}