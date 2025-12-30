import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_constants.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> makePayment({
    required BuildContext context,
    required String bookingId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Create Payment Intent on Backend
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.paymentsEndpoint}/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Failed to create payment intent');
      }

      final clientSecret = data['clientSecret'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Turf War Platform',
          style: ThemeMode.system,
        ),
      );

      // 3. Display Payment Sheet
      await _displayPaymentSheet(context);

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _displayPaymentSheet(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled, no need to show error
        return;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
