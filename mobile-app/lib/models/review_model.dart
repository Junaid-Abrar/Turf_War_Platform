class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? '',
      userName: json['user']['name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
