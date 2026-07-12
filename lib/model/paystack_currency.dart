/// Typed enum of currencies supported by Paystack.
///
/// Use this instead of bare strings to avoid typos in currency codes.
///
/// Example:
/// ```dart
/// await PayWithPayStack().now(
///   currency: PaystackCurrency.ghs.value,
///   ...
/// );
/// ```
///
/// See also: [Paystack supported currencies](https://paystack.com/docs/payments/multi-currency)
enum PaystackCurrency {
  /// Nigerian Naira
  ngn('NGN'),

  /// Ghanaian Cedi
  ghs('GHS'),

  /// South African Rand
  zar('ZAR'),

  /// United States Dollar
  usd('USD'),

  /// Kenyan Shilling
  kes('KES'),

  /// West African CFA Franc
  xof('XOF'),

  /// Egyptian Pound
  egp('EGP'),

  /// Rwandan Franc
  rwf('RWF');

  /// The ISO 4217 currency code sent to the Paystack API.
  final String value;

  const PaystackCurrency(this.value);

  /// Returns a [PaystackCurrency] from its ISO 4217 [code] (case-insensitive),
  /// or `null` if no match is found.
  ///
  /// Example:
  /// ```dart
  /// PaystackCurrency.fromString('GHS') // => PaystackCurrency.ghs
  /// PaystackCurrency.fromString('ghs') // => PaystackCurrency.ghs
  /// PaystackCurrency.fromString('XYZ') // => null
  /// ```
  static PaystackCurrency? fromString(String code) {
    final upper = code.toUpperCase();
    for (final c in PaystackCurrency.values) {
      if (c.value == upper) return c;
    }
    return null;
  }

  @override
  String toString() => value;
}
