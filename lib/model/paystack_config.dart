/// App-level default configuration for `pay_with_paystack`.
///
/// Set once at app startup using [PayWithPayStack.configure] to avoid
/// repeating your public key, currency and callback URL on every call.
///
/// ## Example
/// ```dart
/// // In main() or your DI setup:
/// PayWithPayStack.configure(PaystackConfig(
///   publicKey: 'pk_live_xxxxxxxxxxxxxxxxxxxx',
///   currency: 'GHS',
///   callbackUrl: 'https://my-app.com/payment/callback',
///   enableLogging: false,
/// ));
///
/// // Later — publicKey / currency / callbackUrl can be omitted:
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
  /// Your Paystack **public** key (`pk_live_…` or `pk_test_…`).
  ///
  /// This is the only key that should ever be embedded in a client app.
  /// Never use your secret key (`sk_…`) here.
  final String publicKey;

  /// ISO 4217 currency code (e.g. `'GHS'`, `'NGN'`).
  ///
  /// Can also be set using [PaystackCurrency.value].
  final String? currency;

  /// Callback URL that Paystack redirects to after checkout.
  ///
  /// Your **backend** at this URL should verify the transaction using the
  /// Paystack secret key server-side (e.g. via `GET /transaction/verify/:ref`).
  final String? callbackUrl;

  /// When `true`, request/response details are printed to the console
  /// via `debugPrint` (no-op in release mode).
  final bool enableLogging;

  /// Maximum time to wait for the Paystack API to respond before timing out.
  ///
  /// Defaults to 30 seconds.
  final Duration timeout;

  const PaystackConfig({
    required this.publicKey,
    this.currency,
    this.callbackUrl,
    this.enableLogging = false,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  String toString() => 'PaystackConfig('
      'key: ${publicKey.substring(0, 8)}…, '
      'currency: $currency, '
      'logging: $enableLogging, '
      'timeout: ${timeout.inSeconds}s'
      ')';
}
