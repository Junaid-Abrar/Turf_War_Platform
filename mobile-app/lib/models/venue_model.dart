class VenueModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final double pricePerHour;
  final List<String> images;
  final List<String> amenities;
  final String ownerId;
  final double averageRating;

  const VenueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    required this.images,
    required this.amenities,
    required this.ownerId,
    this.averageRating = 0.0,
  });

  String? get primaryImage => images.isNotEmpty ? images.first : null;

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    final dynamic owner = json['owner'];

    return VenueModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Venue',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      pricePerHour: (json['pricePerHour'] as num? ?? 0).toDouble(),
      images: List<String>.from(json['images'] as List? ?? const <String>[]),
      amenities:
          List<String>.from(json['amenities'] as List? ?? const <String>[]),
      // `owner` is a raw id on list endpoints and a populated document on some
      // detail endpoints.
      ownerId: owner is Map
          ? (owner['_id'] as String? ?? '')
          : (owner as String? ?? ''),
      averageRating: (json['averageRating'] as num? ?? 0).toDouble(),
    );
  }
}
