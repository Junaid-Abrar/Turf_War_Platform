import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/venue_model.dart';
import '../../../models/review_model.dart';
import '../../../providers/venue_provider.dart';
import '../../../providers/user_provider.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

class VenueDetailsScreen extends StatefulWidget {
  final VenueModel venue;

  const VenueDetailsScreen({super.key, required this.venue});

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  void _fetchReviews() async {
    try {
      final reviews = await Provider.of<VenueProvider>(context, listen: false).getReviews(widget.venue.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  void _showAddReviewDialog() {
    double rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<double>(
              value: rating,
              items: List.generate(5, (index) => index + 1).map((r) => DropdownMenuItem(
                value: r.toDouble(),
                child: Row(
                  children: [
                    Text('$r '),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              )).toList(),
              onChanged: (val) => rating = val!,
              decoration: const InputDecoration(labelText: 'Rating'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Comment'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<VenueProvider>(context, listen: false).addReview(
                  widget.venue.id, rating, commentController.text
                );
                _fetchReviews(); // Refresh
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review added!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add review: $e')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwner = currentUser != null && currentUser.id == widget.venue.ownerId;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible AppBar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.venue.name, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 10)])),
              background: widget.venue.images.isNotEmpty
                ? Image.network(widget.venue.images[0], fit: BoxFit.cover)
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
                          Text(widget.venue.name, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(widget.venue.location, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                widget.venue.averageRating > 0 
                                  ? widget.venue.averageRating.toStringAsFixed(1) 
                                  : 'New',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Text('(${_reviews.length} reviews)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Text('\$${widget.venue.pricePerHour}/hr', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(widget.venue.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.venue.amenities.map((a) => Chip(
                      label: Text(a),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    )).toList(),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
                      if (!isOwner)
                        TextButton.icon(
                          onPressed: _showAddReviewDialog,
                          icon: const Icon(Icons.edit),
                          label: const Text('Write Review'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.grey))
                  else
                    ..._reviews.map((review) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(review.userName[0])),
                        title: Row(
                          children: [
                            Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(review.rating.toString()),
                          ],
                        ),
                        subtitle: Text(review.comment),
                      ),
                    )),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isOwner
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, color: Colors.green),
                  SizedBox(width: 8),
                  Text('This is your venue', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        receiverId: widget.venue.ownerId, 
                        receiverName: 'Owner'
                      )
                    )
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.chat, color: Colors.green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(venue: widget.venue)));
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
          ],
        ),
      ),
    );
  }
}
