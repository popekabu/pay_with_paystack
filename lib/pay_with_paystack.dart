library pay_with_paystack;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_bearer.dart';
import 'package:pay_with_paystack/model/paystack_channel.dart';
import 'package:pay_with_paystack/model/paystack_config.dart';
import 'package:pay_with_paystack/model/paystack_exception.dart';
import 'package:pay_with_paystack/model/paystack_metadata.dart';
import 'package:pay_with_paystack/src/paystack_pay_now.dart';
import 'package:uuid/uuid.dart';

export 'package:pay_with_paystack/model/authorization.dart';
export 'package:pay_with_paystack/model/customer.dart';
export 'package:pay_with_paystack/model/payment_data.dart';
export 'package:pay_with_paystack/model/paystack_bearer.dart';
export 'package:pay_with_paystack/model/paystack_bulk_charge.dart';
export 'package:pay_with_paystack/model/paystack_channel.dart';
export 'package:pay_with_paystack/model/paystack_config.dart';
export 'package:pay_with_paystack/model/paystack_currency.dart';
export 'package:pay_with_paystack/model/paystack_exception.dart';
export 'package:pay_with_paystack/model/paystack_metadata.dart';

/// Entry point for the `pay_with_paystack` plugin.
///
/// Call [now] to launch the Paystack checkout WebView, [chargeAuthorization]
/// to silently charge a returning customer, or [generateUuidV4] to generate
/// a unique transaction reference.
///
/// ## Global configuration (optional)
///
/// Call [configure] once at app startup to set shared defaults so you don't
/// repeat `secretKey`, `currency`, and `callbackUrl` on every call:
///
/// ```dart
/// PayWithPayStack.configure(PaystackConfig(
///   secretKey: 'sk_live_xxxx',
///   currency: 'GHS',
///   callbackUrl: 'https://my-app.com/callback',
/// ));
/// ```
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
  // ── Global config ──────────────────────────────────────────────────────────

  static PaystackConfig? _globalConfig;

  /// Sets app-level defaults for all [PayWithPayStack] calls.
  ///
  /// Call this once in `main()` (or your DI setup) so that [secretKey],
  /// [currency], and [callbackUrl] can be omitted on individual calls.
  ///
  /// ```dart
  /// PayWithPayStack.configure(PaystackConfig(
  ///   secretKey: 'sk_live_xxxx',
  ///   currency: 'GHS',
  ///   callbackUrl: 'https://my-app.com/callback',
  ///   enableLogging: kDebugMode,
  /// ));
  /// ```
  static void configure(PaystackConfig config) {
    _globalConfig = config;
  }

  /// Clears the current global config. Useful for testing.
  static void clearConfig() => _globalConfig = null;

  /// Returns the currently active global [PaystackConfig], or `null` if
  /// [configure] has not been called.
  static PaystackConfig? get currentConfig => _globalConfig;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Generates a UUID v4 string suitable for use as a unique transaction
  /// reference.
  String generateUuidV4() => const Uuid().v4();

  // ── now() ──────────────────────────────────────────────────────────────────

  /// Launches the Paystack payment WebView and resolves with [PaymentData]
  /// when the checkout session ends (whether successful or not).
  ///
  /// Parameters marked as *optional if config set* can be omitted when a
  /// global [PaystackConfig] has been set via [configure].
  ///
  /// ---
  /// ### Core (required unless global config provides a default)
  /// - [context] — current [BuildContext] used for navigation.
  /// - [customerEmail] — the customer's email address.
  /// - [reference] — unique transaction reference (use [generateUuidV4]).
  /// - [amount] — amount in the **major** unit (e.g. `50.0` = GHS 50.00).
  ///   Converted to pesewas / kobo automatically.
  /// - [transactionCompleted] — called with [PaymentData] on success.
  /// - [transactionNotCompleted] — called with a status string on failure.
  /// - [secretKey] — your Paystack secret key. *Optional if config set.*
  /// - [currency] — ISO 4217 code e.g. `"GHS"`. *Optional if config set.*
  /// - [callbackUrl] — redirect URL after payment. *Optional if config set.*
  ///
  /// ---
  /// ### Cancel callback
  /// - [transactionCancelled] — called when the user explicitly closes the
  ///   checkout without making a payment attempt. Distinct from
  ///   [transactionNotCompleted], which fires after a failed attempt.
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
  ///   transaction's metadata. Each item may include an optional `imageUrl`.
  /// - [metadata] — raw additional key-value data for the transaction.
  ///
  /// ---
  /// ### Network options
  /// - [timeout] — maximum time to wait for the Paystack API. Defaults to
  ///   30 seconds (or the value set in [PaystackConfig]).
  /// - [enableLogging] — if `true`, request/response details are printed to
  ///   the console via `debugPrint` (no-op in release mode).
  /// - [onTimeout] — called when the request times out. If `null`,
  ///   [transactionNotCompleted] is called with `'timeout'`.
  ///
  /// ---
  /// ### UI customisation
  /// - [showAppBar] — show the AppBar above the WebView (default `true`).
  /// - [appBarTitle] — AppBar title (default `"Secure Checkout"`).
  /// - [appBarColor] — AppBar background color.
  /// - [appBarTextColor] — AppBar text/icon color.
  /// - [progressColor] — accent color for the loading/progress indicators and
  ///   the "Try Again" button. Defaults to Paystack green (`#00C386`).
  /// - [progressBackgroundColor] — track color for the linear progress bar.
  ///   Defaults to `Color(0xFF1E1E2E)`.
  /// - [loadingWidget] — custom widget while the session initialises.
  /// - [errorWidget] — custom error screen builder (receives error + retry).
  Future<PaymentData?> now({
    // ── Required ─────────────────────────────────────────────────────────────
    required BuildContext context,
    required String customerEmail,
    required String reference,
    required double amount,
    required Function(PaymentData data) transactionCompleted,
    required Function(String reason) transactionNotCompleted,

    // ── Optional if global config provides them ───────────────────────────────
    String? secretKey,
    String? currency,
    String? callbackUrl,

    // ── Cancel callback ───────────────────────────────────────────────────────
    VoidCallback? transactionCancelled,

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

    // ── Network options ───────────────────────────────────────────────────────
    Duration? timeout,
    bool? enableLogging,
    VoidCallback? onTimeout,

    // ── UI customisation ──────────────────────────────────────────────────────
    bool showAppBar = true,
    String appBarTitle = 'Secure Checkout',
    Color? appBarColor,
    Color? appBarTextColor,

    /// Accent color for the loading spinner, linear progress bar, verification
    /// overlay, and the "Try Again" button. Defaults to Paystack green.
    Color? progressColor,

    /// Track color for the linear progress indicator. Defaults to
    /// `Color(0xFF1E1E2E)`.
    Color? progressBackgroundColor,

    Widget? loadingWidget,
    Widget Function(String error, VoidCallback retry)? errorWidget,
  }) {
    // Resolve values: direct param > global config > error.
    final resolvedKey = secretKey ?? _globalConfig?.secretKey;
    final resolvedCurrency = currency ?? _globalConfig?.currency;
    final resolvedCallbackUrl = callbackUrl ?? _globalConfig?.callbackUrl;
    final resolvedTimeout =
        timeout ?? _globalConfig?.timeout ?? const Duration(seconds: 30);
    final resolvedLogging =
        enableLogging ?? _globalConfig?.enableLogging ?? false;

    assert(
      resolvedKey != null,
      'secretKey must be provided either directly or via PayWithPayStack.configure().',
    );
    assert(
      resolvedCurrency != null,
      'currency must be provided either directly or via PayWithPayStack.configure().',
    );
    assert(
      resolvedCallbackUrl != null,
      'callbackUrl must be provided either directly or via PayWithPayStack.configure().',
    );

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
          secretKey: resolvedKey!,
          email: customerEmail,
          reference: reference,
          currency: resolvedCurrency!,
          amount: amount,
          callbackUrl: resolvedCallbackUrl!,
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
          transactionCancelled: transactionCancelled,
          showAppBar: showAppBar,
          appBarTitle: appBarTitle,
          appBarColor: appBarColor,
          appBarTextColor: appBarTextColor,
          progressColor: progressColor,
          progressBackgroundColor: progressBackgroundColor,
          loadingWidget: loadingWidget,
          errorWidget: errorWidget,
          timeout: resolvedTimeout,
          enableLogging: resolvedLogging,
          onTimeout: onTimeout,
        ),
      ),
    );
  }

  // ── chargeAuthorization() ──────────────────────────────────────────────────

  /// Charges a returning customer silently using a saved authorization code,
  /// without opening a WebView.
  ///
  /// Requires a valid [authorizationCode] from a previous successful
  /// transaction (available as `data.authorization?.authorizationCode`
  /// from [PaymentData]).
  ///
  /// > **Important**: Only works with reusable authorizations
  /// > (`data.authorization?.reusable == true`).
  ///
  /// ## Example
  /// ```dart
  /// await PayWithPayStack().chargeAuthorization(
  ///   secretKey: 'sk_live_xxxx',
  ///   authorizationCode: 'AUTH_xxxxxxxxxx',
  ///   customerEmail: 'user@example.com',
  ///   amount: 50.00,
  ///   currency: 'GHS',
  ///   reference: PayWithPayStack().generateUuidV4(),
  ///   transactionCompleted: (data) => print('Recharged: ${data.reference}'),
  ///   transactionNotCompleted: (reason) => print('Failed: $reason'),
  /// );
  /// ```
  Future<PaymentData?> chargeAuthorization({
    required String authorizationCode,
    required String customerEmail,
    required double amount,
    required Function(PaymentData data) transactionCompleted,
    required Function(String reason) transactionNotCompleted,

    // Optional if global config provides them
    String? secretKey,
    String? currency,
    String? reference,
    Map<String, dynamic>? metadata,
    Duration? timeout,
    bool? enableLogging,
  }) async {
    final resolvedKey = secretKey ?? _globalConfig?.secretKey;
    final resolvedCurrency = currency ?? _globalConfig?.currency;
    final resolvedRef = reference ?? generateUuidV4();
    final resolvedTimeout =
        timeout ?? _globalConfig?.timeout ?? const Duration(seconds: 30);
    final resolvedLogging =
        enableLogging ?? _globalConfig?.enableLogging ?? false;

    assert(
      resolvedKey != null,
      'secretKey must be provided either directly or via PayWithPayStack.configure().',
    );
    assert(
      resolvedCurrency != null,
      'currency must be provided either directly or via PayWithPayStack.configure().',
    );

    void log(String msg) {
      if (resolvedLogging) debugPrint('[PayWithPaystack] $msg');
    }

    final requestBody = <String, dynamic>{
      'authorization_code': authorizationCode,
      'email': customerEmail,
      'amount': (amount * 100).toStringAsFixed(0),
      'currency': resolvedCurrency,
      'reference': resolvedRef,
      if (metadata != null) 'metadata': metadata,
    };

    log('→ POST /transaction/charge_authorization');
    log('  body: ${jsonEncode(requestBody)}');

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(
                'https://api.paystack.co/transaction/charge_authorization'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $resolvedKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(resolvedTimeout);
    } on Exception catch (e) {
      log('[ERROR] $e');
      transactionNotCompleted('network_error: ${e.toString()}');
      return null;
    }

    log('← ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = decoded['data']?['status']?.toString();
      if (status == 'success') {
        final data = PaymentData.fromJson(decoded['data']);
        transactionCompleted(data);
        return data;
      } else {
        transactionNotCompleted(status ?? 'unknown');
        return null;
      }
    }

    throw PaystackException(
      message: 'Charge authorization failed',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }
}
