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
        // No PaymentIntent exists to verify, so the backend only accepts this
        // when it is itself configured with DEMO_MODE=true. Without this
        // call the booking is never actually marked paid server-side, and
        // the next refetch reverts the optimistic "paid" state back to
        // unpaid — the demo needs this exactly as much as the real flow does.
        try {
          await _paymentService.confirmPayment(bookingId);
        } on ApiException catch (e) {
          AppLogger.error('Demo payment confirm call failed', e);
        }
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

      // The sheet returning without throwing only means Stripe accepted the
      // payment client-side — the backend's booking record is still 'unpaid'
      // until the async webhook lands. Confirm synchronously here so a
      // refetch right after this returns doesn't read stale pre-webhook
      // status and put the "Pay" button back (the bug this guards against).
      //
      // The card has already been charged by this point, so a failure to
      // reach /payments/confirm (e.g. a dropped connection) must not be
      // reported as a payment failure — that would risk the user paying
      // twice. The webhook is still in flight and will mark the booking paid
      // server-side even if this call never lands.
      try {
        await _paymentService.confirmPayment(bookingId);
      } on ApiException catch (e) {
        AppLogger.error('Payment confirm call failed after Stripe success', e);
      }

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
