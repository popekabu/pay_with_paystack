/// Represents a single item in a Paystack bulk charge batch.
///
/// Pass a list of these to `POST /bulkcharge` on the Paystack API to charge
/// multiple authorizations in a single request. This model is a data
/// container; the actual API call is your responsibility.
///
/// ## Example
/// ```dart
/// final items = [
///   PaystackBulkChargeItem(
///     authorizationCode: 'AUTH_xxxxx',
///     amount: 50.00,
///     reference: PayWithPayStack().generateUuidV4(),
///     email: 'user1@example.com',
///   ),
///   PaystackBulkChargeItem(
///     authorizationCode: 'AUTH_yyyyy',
///     amount: 20.00,
///     reference: PayWithPayStack().generateUuidV4(),
///     email: 'user2@example.com',
///   ),
/// ];
///
/// // Serialise for the Paystack bulk charge API:
/// final body = jsonEncode(items.map((i) => i.toJson()).toList());
/// ```
class PaystackBulkChargeItem {
  /// The authorization code from a previous successful transaction.
  /// Obtained from [PaymentData.authorization?.authorizationCode].
  final String authorizationCode;

  /// Amount to charge in the **major** currency unit (e.g. `50.00` for GHS 50).
  /// Converted to the subunit automatically in [toJson].
  final double amount;

  /// A unique reference for this charge in the batch.
  final String reference;

  /// The email address of the customer being charged.
  final String email;

  const PaystackBulkChargeItem({
    required this.authorizationCode,
    required this.amount,
    required this.reference,
    required this.email,
  });

  /// Serialises this item to the JSON format expected by the Paystack
  /// `POST /bulkcharge` endpoint.
  ///
  /// The [amount] is converted from the major unit to the subunit
  /// (e.g. GHS 50.00 → 5000 pesewas).
  Map<String, dynamic> toJson() => {
        'authorization': authorizationCode,
        'amount': (amount * 100).toStringAsFixed(0),
        'reference': reference,
        'email': email,
      };

  @override
  String toString() =>
      'PaystackBulkChargeItem(auth: $authorizationCode, amount: $amount, ref: $reference)';
}
