class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // `user` is populated by the reviews controller, but a review whose author
    // has since been deleted comes back as a bare id — indexing into it
    // unconditionally used to throw while building the list.
    final dynamic user = json['user'];
    final String name =
        user is Map ? (user['name'] as String? ?? 'Anonymous') : 'Anonymous';

    return ReviewModel(
      id: json['_id'] as String? ?? '',
      userName: name.isEmpty ? 'Anonymous' : name,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
