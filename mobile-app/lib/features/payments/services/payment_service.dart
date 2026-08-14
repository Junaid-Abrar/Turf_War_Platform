import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class PaymentService {
  final ApiClient _api;

  const PaymentService(this._api);

  /// Asks the backend to create a Stripe PaymentIntent for a booking and
  /// returns its client secret. The backend verifies that the booking belongs
  /// to the caller (Phase 1 ownership check).
  Future<String> createPaymentIntent(String bookingId) async {
    final Map<String, dynamic> body = await _api.post(
      '/payments/create-payment-intent',
      body: <String, dynamic>{'bookingId': bookingId},
    );

    final String? clientSecret = body['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw const ApiException(
        'Payment could not be started. Please try again.',
        kind: ApiExceptionKind.unknown,
      );
    }
    return clientSecret;
  }

  /// Asks the backend to verify the PaymentIntent with Stripe directly and
  /// mark the booking paid, instead of waiting on the async webhook. Must be
  /// awaited before any refetch of booking state, or the refetch can race the
  /// webhook and read the booking back as still unpaid.
  ///
  /// Returns true once the backend confirms `paymentStatus == 'paid'`.
  Future<bool> confirmPayment(String bookingId) async {
    final Map<String, dynamic> body = await _api.post(
      '/payments/confirm',
      body: <String, dynamic>{'bookingId': bookingId},
    );
    return body['paymentStatus'] == 'paid';
  }
}
