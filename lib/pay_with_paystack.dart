library pay_with_paystack;

import 'package:flutter/material.dart';
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_channel.dart';
import 'package:pay_with_paystack/src/paystack_pay_now.dart';
import 'package:uuid/uuid.dart';

export 'package:pay_with_paystack/model/authorization.dart';
export 'package:pay_with_paystack/model/customer.dart';
export 'package:pay_with_paystack/model/payment_data.dart';
export 'package:pay_with_paystack/model/paystack_channel.dart';
export 'package:pay_with_paystack/model/paystack_exception.dart';

/// Entry point for the `pay_with_paystack` plugin.
///
/// Call [now] to launch the Paystack checkout WebView. Use [generateUuidV4]
/// to generate a unique transaction reference.
///
/// ## Example
/// ```dart
/// await PayWithPayStack().now(
///   context: context,
///   secretKey: 'sk_live_xxxx',
///   customerEmail: 'user@example.com',
///   reference: PayWithPayStack().generateUuidV4(),
///   currency: 'GHS',
///   amount: 50.00,
///   callbackUrl: 'https://your-callback.com',
///   channels: [PaystackChannel.card, PaystackChannel.mobileMoney],
///   transactionCompleted: (data) => print('Paid: ${data.amountInMajorUnit}'),
///   transactionNotCompleted: (reason) => print('Failed: $reason'),
/// );
/// ```
class PayWithPayStack {
  /// Generates a UUID v4 string suitable for use as a unique transaction
  /// reference.
  String generateUuidV4() => const Uuid().v4();

  /// Launches the Paystack payment WebView and resolves with the [PaymentData]
  /// when the checkout session ends (whether successful or not).
  ///
  /// ### Required parameters
  /// - [context] — the current [BuildContext], used for navigation.
  /// - [secretKey] — your Paystack secret key (`sk_live_…` or `sk_test_…`).
  /// - [customerEmail] — the customer's email address.
  /// - [reference] — a unique transaction reference (use [generateUuidV4]).
  /// - [callbackUrl] — the URL Paystack redirects to after payment; must match
  ///   what is configured in your Paystack dashboard.
  /// - [currency] — ISO 4217 currency code (e.g. `"GHS"`, `"NGN"`, `"ZAR"`).
  /// - [amount] — amount to charge in the **major** currency unit (e.g. `50.0`
  ///   for GHS 50.00). The plugin converts this to pesewas / kobo automatically.
  /// - [transactionCompleted] — called with a [PaymentData] object when the
  ///   transaction succeeds.
  /// - [transactionNotCompleted] — called with a status string when the
  ///   transaction does not succeed.
  ///
  /// ### Optional parameters
  /// - [channels] — list of [PaystackChannel] values to restrict the payment
  ///   options shown to the customer.
  /// - [plan] — Paystack subscription plan code.
  /// - [metadata] — additional key-value data attached to the transaction.
  /// - [showAppBar] — whether to show an AppBar above the WebView. Defaults
  ///   to `true`.
  /// - [appBarTitle] — title shown in the AppBar. Defaults to
  ///   `"Secure Checkout"`.
  /// - [appBarColor] — background color of the AppBar.
  /// - [appBarTextColor] — foreground/text color of the AppBar.
  /// - [loadingWidget] — a custom widget to display while the payment session
  ///   is being initialised. Replaces the default branded loader.
  /// - [errorWidget] — a builder for a custom error screen. Receives the
  ///   error message and a retry callback.
  Future<PaymentData?> now({
    /// Current [BuildContext], required for navigation.
    required BuildContext context,

    /// Paystack secret key (`sk_live_…` or `sk_test_…`).
    required String secretKey,

    /// Customer's email address.
    required String customerEmail,

    /// Unique transaction reference (use [generateUuidV4]).
    required String reference,

    /// Redirect URL after payment, must match your Paystack dashboard setting.
    required String callbackUrl,

    /// ISO 4217 currency code, e.g. `"GHS"`, `"NGN"`, `"ZAR"`.
    required String currency,

    /// Amount to charge in the major currency unit (e.g. `50.0` = GHS 50.00).
    required double amount,

    /// Called with [PaymentData] when the transaction is successful.
    required Function(PaymentData data) transactionCompleted,

    /// Called with a status string when the transaction is not successful.
    required Function(String reason) transactionNotCompleted,

    /// Restrict which payment options are available to the customer.
    List<PaystackChannel>? channels,

    /// Paystack subscription plan code.
    String? plan,

    /// Additional metadata attached to the transaction.
    Map<String, dynamic>? metadata,

    /// Whether to show the AppBar above the WebView. Defaults to `true`.
    bool showAppBar = true,

    /// Title shown in the AppBar. Defaults to `"Secure Checkout"`.
    String appBarTitle = 'Secure Checkout',

    /// Background color of the AppBar.
    Color? appBarColor,

    /// Foreground/text color of the AppBar.
    Color? appBarTextColor,

    /// Custom loading widget shown while the session initialises.
    Widget? loadingWidget,

    /// Custom error widget builder. Receives the error message and a retry
    /// callback.
    Widget Function(String error, VoidCallback retry)? errorWidget,
  }) {
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
