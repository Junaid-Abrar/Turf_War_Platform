import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/logger.dart';
import '../services/payment_service.dart';

/// Outcome of a payment attempt.
///
/// `makePayment` used to take a `BuildContext` and show its own SnackBar from
/// inside the provider — which both reached across an async gap and put
/// presentation logic in the state layer. It now returns one of these and lets
/// the calling widget decide what to render.
enum PaymentStatus { success, cancelled, failed }

@immutable
class PaymentResult {
  final PaymentStatus status;

  /// Populated only when [status] is [PaymentStatus.failed].
  final String? message;

  const PaymentResult._(this.status, [this.message]);

  const PaymentResult.success() : this._(PaymentStatus.success);
  const PaymentResult.cancelled() : this._(PaymentStatus.cancelled);
  const PaymentResult.failed(String message)
      : this._(PaymentStatus.failed, message);

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailure => status == PaymentStatus.failed;
}

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentProvider(this._paymentService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Runs the full pay flow: create the intent, present the Stripe sheet, and
  /// report what happened. Never throws — every failure path maps to a
  /// [PaymentResult].
  Future<PaymentResult> makePayment({required String bookingId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // A web demo has no native Stripe sheet; treat it as a successful
      // simulated payment so the rest of the flow stays clickable.
      if (AppConfig.demoMode || !AppConfig.hasStripeKey) {
        AppLogger.info('Demo mode: simulating a successful payment');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return const PaymentResult.success();
      }

      final String clientSecret =
          await _paymentService.createPaymentIntent(bookingId);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Turf War',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      return const PaymentResult.success();
    } on StripeException catch (e) {
      // Backing out of the sheet is a normal user action, not an error to
      // surface in red.
      if (e.error.code == FailureCode.Canceled) {
        return const PaymentResult.cancelled();
      }
      AppLogger.error('Stripe payment failed', e);
      return PaymentResult.failed(
        e.error.localizedMessage ?? 'Payment failed. Please try again.',
      );
    } on ApiException catch (e) {
      return PaymentResult.failed(e.message);
    } catch (e, s) {
      AppLogger.error('Unexpected payment failure', e, s);
      return const PaymentResult.failed(
        'Payment failed. Please try again.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
