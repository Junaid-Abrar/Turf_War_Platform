class VenueModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final double pricePerHour;
  final List<String> images;
  final List<String> amenities;
  final String ownerId;
  final double averageRating; // Add

  VenueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    required this.images,
    required this.amenities,
    required this.ownerId,
    this.averageRating = 0.0, // Add
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Venue',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      ownerId: json['owner'] is Map ? json['owner']['_id'] : (json['owner'] ?? ''),
      averageRating: (json['averageRating'] ?? 0).toDouble(), // Add
    );
  }
}
