library pay_with_paystack;

import 'package:flutter/material.dart';
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_bearer.dart';
import 'package:pay_with_paystack/model/paystack_channel.dart';
import 'package:pay_with_paystack/model/paystack_metadata.dart';
import 'package:pay_with_paystack/src/paystack_pay_now.dart';
import 'package:uuid/uuid.dart';

export 'package:pay_with_paystack/model/authorization.dart';
export 'package:pay_with_paystack/model/customer.dart';
export 'package:pay_with_paystack/model/payment_data.dart';
export 'package:pay_with_paystack/model/paystack_bearer.dart';
export 'package:pay_with_paystack/model/paystack_channel.dart';
export 'package:pay_with_paystack/model/paystack_exception.dart';
export 'package:pay_with_paystack/model/paystack_metadata.dart';

/// Entry point for the `pay_with_paystack` plugin.
///
/// Call [now] to launch the Paystack checkout WebView. Use [generateUuidV4]
/// to generate a unique transaction reference.
///
/// ## Basic example
/// ```dart
/// await PayWithPayStack().now(
///   context: context,
///   secretKey: 'sk_live_xxxx',
///   customerEmail: 'user@example.com',
///   reference: PayWithPayStack().generateUuidV4(),
///   currency: 'GHS',
///   amount: 50.00,
///   callbackUrl: 'https://your-callback.com',
///   transactionCompleted: (data) => print('Paid: ${data.amountInMajorUnit}'),
///   transactionNotCompleted: (reason) => print('Failed: $reason'),
/// );
/// ```
class PayWithPayStack {
  /// Generates a UUID v4 string suitable for use as a unique transaction
  /// reference.
  String generateUuidV4() => const Uuid().v4();

  /// Launches the Paystack payment WebView and resolves with [PaymentData]
  /// when the checkout session ends (whether successful or not).
  ///
  /// ---
  /// ### Core (required)
  /// - [context] — current [BuildContext] used for navigation.
  /// - [secretKey] — your Paystack secret key (`sk_live_…` or `sk_test_…`).
  /// - [customerEmail] — the customer's email address.
  /// - [reference] — unique transaction reference (use [generateUuidV4]).
  /// - [callbackUrl] — redirect URL after payment; must match your Paystack
  ///   dashboard setting.
  /// - [currency] — ISO 4217 code e.g. `"GHS"`, `"NGN"`, `"ZAR"`.
  /// - [amount] — amount in the **major** unit (e.g. `50.0` = GHS 50.00).
  ///   Converted to pesewas / kobo automatically.
  /// - [transactionCompleted] — called with [PaymentData] on success.
  /// - [transactionNotCompleted] — called with a status string on failure.
  ///
  /// ---
  /// ### Payment channels
  /// - [channels] — restrict which payment options are shown to the customer.
  ///
  /// ---
  /// ### Subscriptions
  /// - [plan] — Paystack subscription plan code.
  /// - [invoiceLimit] — number of times to charge during the plan.
  ///
  /// ---
  /// ### Split payments
  /// - [subaccount] — route/split payment to a subaccount (`ACCT_xxxxxxxx`).
  /// - [splitCode] — use a pre-defined multi-recipient split group (`SPL_xxx`).
  /// - [transactionCharge] — flat fee (major unit) for the main account
  ///   when splitting. Overrides the default percentage.
  /// - [bearer] — who pays the Paystack transaction fees
  ///   ([PaystackBearer.account] or [PaystackBearer.subaccount]).
  ///
  /// ---
  /// ### Customer prefill
  /// - [customerFirstName] — pre-fills the customer's first name.
  /// - [customerLastName] — pre-fills the customer's last name.
  /// - [customerPhone] — pre-fills the customer's phone number.
  ///
  /// ---
  /// ### Structured metadata
  /// - [customFields] — list of [PaystackCustomField] objects shown on the
  ///   Paystack Dashboard for this transaction.
  /// - [cartItems] — list of [PaystackCartItem] line items attached to the
  ///   transaction's metadata.
  /// - [metadata] — raw additional key-value data for the transaction.
  ///
  /// ---
  /// ### UI customisation
  /// - [showAppBar] — show the AppBar above the WebView (default `true`).
  /// - [appBarTitle] — AppBar title (default `"Secure Checkout"`).
  /// - [appBarColor] — AppBar background color.
  /// - [appBarTextColor] — AppBar text/icon color.
  /// - [loadingWidget] — custom widget while the session initialises.
  /// - [errorWidget] — custom error screen builder (receives error + retry).
  Future<PaymentData?> now({
    // ── Required ─────────────────────────────────────────────────────────────
    required BuildContext context,
    required String secretKey,
    required String customerEmail,
    required String reference,
    required String callbackUrl,
    required String currency,
    required double amount,
    required Function(PaymentData data) transactionCompleted,
    required Function(String reason) transactionNotCompleted,

    // ── Payment channels ──────────────────────────────────────────────────────
    List<PaystackChannel>? channels,

    // ── Subscriptions ─────────────────────────────────────────────────────────
    String? plan,
    int? invoiceLimit,

    // ── Split payments ────────────────────────────────────────────────────────
    /// Subaccount code to route/split the payment to (e.g. `ACCT_xxxxxxxxxx`).
    String? subaccount,

    /// Pre-defined split group code (e.g. `SPL_xxxxxxxxxx`).
    String? splitCode,

    /// Flat fee (in major currency unit) that goes to the main account.
    /// Overrides the default percentage split when using [subaccount].
    double? transactionCharge,

    /// Who bears the Paystack transaction fees.
    PaystackBearer? bearer,

    // ── Customer prefill ──────────────────────────────────────────────────────
    /// Pre-fills the customer's first name on the checkout form.
    String? customerFirstName,

    /// Pre-fills the customer's last name on the checkout form.
    String? customerLastName,

    /// Pre-fills the customer's phone number on the checkout form.
    String? customerPhone,

    // ── Structured metadata ───────────────────────────────────────────────────
    /// Custom fields shown on the Paystack Dashboard for this transaction.
    List<PaystackCustomField>? customFields,

    /// Cart line items attached to the transaction's metadata.
    List<PaystackCartItem>? cartItems,

    /// Raw additional metadata for the transaction.
    Map<String, dynamic>? metadata,

    // ── UI customisation ──────────────────────────────────────────────────────
    bool showAppBar = true,
    String appBarTitle = 'Secure Checkout',
    Color? appBarColor,
    Color? appBarTextColor,
    Widget? loadingWidget,
    Widget Function(String error, VoidCallback retry)? errorWidget,
  }) {
    // Build a merged metadata map that incorporates customerFirstName/LastName/Phone
    // as custom_fields so they appear on the Paystack Dashboard.
    final prefillFields = <PaystackCustomField>[
      if (customerFirstName != null)
        PaystackCustomField(
          displayName: 'First Name',
          variableName: 'first_name',
          value: customerFirstName,
        ),
      if (customerLastName != null)
        PaystackCustomField(
          displayName: 'Last Name',
          variableName: 'last_name',
          value: customerLastName,
        ),
      if (customerPhone != null)
        PaystackCustomField(
          displayName: 'Phone',
          variableName: 'phone',
          value: customerPhone,
        ),
    ];

    // Merge caller-supplied customFields with the prefill fields.
    final mergedCustomFields = [
      ...prefillFields,
      if (customFields != null) ...customFields,
    ];

    return Navigator.push<PaymentData>(
      context,
      MaterialPageRoute(
        builder: (context) => PaystackPayNow(
          secretKey: secretKey,
          email: customerEmail,
          reference: reference,
          currency: currency,
          amount: amount,
          callbackUrl: callbackUrl,
          paymentChannel:
              channels != null ? PaystackChannel.toStringList(channels) : null,
          plan: plan,
          invoiceLimit: invoiceLimit,
          subaccount: subaccount,
          splitCode: splitCode,
          transactionCharge: transactionCharge,
          bearer: bearer,
          customerFirstName: customerFirstName,
          customerLastName: customerLastName,
          customerPhone: customerPhone,
          customFields:
              mergedCustomFields.isNotEmpty ? mergedCustomFields : null,
          cartItems: cartItems,
          metadata: metadata,
          transactionCompleted: transactionCompleted,
          transactionNotCompleted: transactionNotCompleted,
          showAppBar: showAppBar,
          appBarTitle: appBarTitle,
          appBarColor: appBarColor,
          appBarTextColor: appBarTextColor,
          loadingWidget: loadingWidget,
          errorWidget: errorWidget,
        ),
      ),
    );
  }
}
