/// App-level default configuration for `pay_with_paystack`.
///
/// Set once at app startup using [PayWithPayStack.configure] to avoid
/// repeating your secret key, currency and callback URL on every call.
///
/// ## Example
/// ```dart
/// // In main() or your DI setup:
/// PayWithPayStack.configure(PaystackConfig(
///   secretKey: 'sk_live_xxxxxxxxxxxxxxxxxxxx',
///   currency: 'GHS',
///   callbackUrl: 'https://my-app.com/payment/callback',
///   enableLogging: false,
/// ));
///
/// // Later — secretKey / currency / callbackUrl can be omitted:
/// await PayWithPayStack().now(
///   context: context,
///   customerEmail: 'user@example.com',
///   reference: PayWithPayStack().generateUuidV4(),
///   amount: 50.00,
///   transactionCompleted: (data) => print('Paid!'),
///   transactionNotCompleted: (reason) => print('Failed: $reason'),
/// );
/// ```
class PaystackConfig {
  /// Your Paystack secret key (`sk_live_…` or `sk_test_…`).
  final String secretKey;

  /// ISO 4217 currency code (e.g. `'GHS'`, `'NGN'`).
  ///
  /// Can also be set using [PaystackCurrency.value].
  final String? currency;

  /// Callback URL that Paystack redirects to after checkout.
  final String? callbackUrl;

  /// When `true`, request/response details are printed to the console
  /// via `debugPrint` (no-op in release mode).
  final bool enableLogging;

  /// Maximum time to wait for the Paystack API to respond before timing out.
  ///
  /// Defaults to 30 seconds.
  final Duration timeout;

  const PaystackConfig({
    required this.secretKey,
    this.currency,
    this.callbackUrl,
    this.enableLogging = false,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  String toString() => 'PaystackConfig('
      'key: ${secretKey.substring(0, 8)}…, '
      'currency: $currency, '
      'logging: $enableLogging, '
      'timeout: ${timeout.inSeconds}s'
      ')';
}
