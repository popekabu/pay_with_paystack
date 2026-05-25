/// Represents a custom field that appears on the Paystack Dashboard when
/// viewing a transaction.
///
/// Pass a list of these via [PayWithPayStack.now]'s [customFields] parameter.
///
/// Example:
/// ```dart
/// customFields: [
///   PaystackCustomField(
///     displayName: 'Order ID',
///     variableName: 'order_id',
///     value: '#ORD-1234',
///   ),
///   PaystackCustomField(
///     displayName: 'Customer Phone',
///     variableName: 'phone',
///     value: '+233244000000',
///   ),
/// ],
/// ```
class PaystackCustomField {
  /// The label shown on the Paystack Dashboard for this field.
  final String displayName;

  /// An internal snake_case key for this field.
  final String variableName;

  /// The value of this field.
  final String value;

  const PaystackCustomField({
    required this.displayName,
    required this.variableName,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'variable_name': variableName,
        'value': value,
      };

  @override
  String toString() =>
      'PaystackCustomField($displayName: $value)';
}

/// Represents a single line item in a customer's cart.
///
/// Pass a list of these via [PayWithPayStack.now]'s [cartItems] parameter.
/// These appear in the Paystack Dashboard under the transaction's metadata.
///
/// Example:
/// ```dart
/// cartItems: [
///   PaystackCartItem(name: 'Wireless Headphones', amount: 15000, quantity: 1),
///   PaystackCartItem(name: 'Phone Case', amount: 2500, quantity: 2),
/// ],
/// ```
class PaystackCartItem {
  /// Product or item name.
  final String name;

  /// Price of a single unit in the **major** currency unit
  /// (e.g. `15.00` for GHS 15.00). The plugin converts this to
  /// the subunit (pesewas/kobo) automatically when building the metadata.
  final double amount;

  /// Number of units purchased. Defaults to `1`.
  final int quantity;

  const PaystackCartItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': (amount * 100).toStringAsFixed(0),
        'quantity': quantity,
      };

  @override
  String toString() =>
      'PaystackCartItem($name × $quantity @ $amount)';
}
