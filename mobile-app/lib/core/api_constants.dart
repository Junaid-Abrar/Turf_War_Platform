import 'dart:io';

class ApiConstants {
  // Use the Ngrok URL for reliable connectivity
  static const String _tunnelUrl = 'https://denae-oximetric-psychogenetically.ngrok-free.dev'; 

  static String get baseUrl {
    return '$_tunnelUrl/api';
  }

  static const String authEndpoint = '/auth';
  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
}