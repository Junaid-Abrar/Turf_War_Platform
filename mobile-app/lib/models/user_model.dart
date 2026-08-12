class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  bool get isAdmin => role == 'admin';
  bool get isVenueOwner => role == 'venue_owner';

  /// True for the roles allowed to create venues.
  bool get canManageVenues => isAdmin || isVenueOwner;

  /// Uppercase initial for avatar placeholders.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      // `/auth/login` returns `id`; `/auth/me` returns a Mongoose doc with `_id`.
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      token: token,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}
