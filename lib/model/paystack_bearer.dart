/// Defines who bears the Paystack transaction fees when using split payments.
///
/// Pass this to [PayWithPayStack.now] via the [bearer] parameter.
enum PaystackBearer {
  /// The main account bears the transaction fees (default).
  account('account'),

  /// The subaccount bears the transaction fees.
  subaccount('subaccount');

  /// The raw string value sent to the Paystack API.
  final String value;

  const PaystackBearer(this.value);
}
