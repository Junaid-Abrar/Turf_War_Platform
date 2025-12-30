import 'venue_model.dart';

class BookingModel {
  final String id;
  final String user;
  final dynamic venue; // Can be a String (ID) or VenueModel
  final String date;
  final String startTime;
  final String endTime;
  final double price;
  final String status;
  final String paymentStatus; // Add
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.user,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    required this.paymentStatus, // Add
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      venue: json['venue'] is Map<String, dynamic>
          ? VenueModel.fromJson(json['venue'])
          : json['venue'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'unpaid', // Add
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
