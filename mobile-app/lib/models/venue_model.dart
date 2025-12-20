class VenueModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final double pricePerHour;
  final List<String> images;
  final List<String> amenities;

  VenueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    required this.images,
    required this.amenities,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Venue',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      // Handle potentially int or double from JSON
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
    );
  }
}
