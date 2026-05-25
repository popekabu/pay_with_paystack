/// Represents the available Paystack payment channels.
///
/// Pass a list of these values to [PayWithPayStack.now] via the [channels]
/// parameter to control which payment options are shown to the user.
///
/// Example:
/// ```dart
/// channels: [PaystackChannel.card, PaystackChannel.mobileMoney]
/// ```
///
/// Note: Channel availability depends on your Paystack account settings and
/// the customer's country.
enum PaystackChannel {
  /// Standard card payment (Visa, Mastercard, Verve, etc.)
  card('card'),

  /// Direct bank debit
  bank('bank'),

  /// USSD short-code payment
  ussd('ussd'),

  /// QR code scan-to-pay
  qr('qr'),

  /// Mobile Money (e.g. MTN MoMo, Vodafone Cash)
  mobileMoney('mobile_money'),

  /// Bank transfer (virtual account / dynamic sort code)
  bankTransfer('bank_transfer'),

  /// EFT (Electronic Funds Transfer — South Africa)
  eft('eft');

  /// The raw string value sent to the Paystack API.
  final String value;

  const PaystackChannel(this.value);

  /// Converts a list of [PaystackChannel] values to the string list expected
  /// by the Paystack API.
  ///
  /// Example:
  /// ```dart
  /// PaystackChannel.toStringList([PaystackChannel.card, PaystackChannel.mobileMoney])
  /// // => ["card", "mobile_money"]
  /// ```
  static List<String> toStringList(List<PaystackChannel> channels) {
    return channels.map((c) => c.value).toList();
  }

  /// Returns a [PaystackChannel] from its raw string [value], or `null` if no
  /// match is found.
  static PaystackChannel? fromString(String value) {
    for (final channel in PaystackChannel.values) {
      if (channel.value == value) return channel;
    }
    return null;
  }
}
