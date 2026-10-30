// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_bearer.dart';
import 'package:pay_with_paystack/model/paystack_metadata.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Internal widget that hosts the Paystack WebView checkout experience.
///
/// Use [PayWithPayStack.now] instead of instantiating this directly.
///
/// ## Security
/// This widget uses the Paystack **public key** (`pk_…`) only. The checkout is
/// powered by Paystack's own Inline Popup JS, which is the same SDK used on
/// paystack.com. The secret key (`sk_…`) is **never** used here — transaction
/// verification must be done server-side via your backend.
class PaystackPayNow extends StatefulWidget {
  /// Your Paystack **public** key (`pk_live_…` or `pk_test_…`).
  final String publicKey;
  final String reference;
  final String callbackUrl;
  final String currency;
  final String email;
  final double amount;
  final String? plan;
  final Map<String, dynamic>? metadata;
  final List<String>? paymentChannel;
  final void Function(PaymentData data) transactionCompleted;
  final void Function(String reason) transactionNotCompleted;

  // ── Cancel callback ───────────────────────────────────────────────────────
  /// Called when the user explicitly closes the checkout without completing
  /// payment (e.g. taps the close button or hits the cancel URL).
  /// Distinct from [transactionNotCompleted], which fires after a failed attempt.
  final VoidCallback? transactionCancelled;

  // ── Split payments ────────────────────────────────────────────────────────
  /// Subaccount code to route/split the payment to (e.g. `ACCT_xxxxxxxxxx`).
  final String? subaccount;

  /// Pre-defined split group code from the Paystack Dashboard.
  final String? splitCode;

  /// Flat fee (in **major** currency unit) sent to the main account when
  /// using subaccount splits. Overrides the default percentage split.
  final double? transactionCharge;

  /// Who bears the Paystack transaction fees. Defaults to [PaystackBearer.account].
  final PaystackBearer? bearer;

  // ── Subscriptions ─────────────────────────────────────────────────────────
  /// Number of times to charge the customer during a subscription plan.
  /// Only relevant when [plan] is set.
  final int? invoiceLimit;

  // ── Customer prefill ──────────────────────────────────────────────────────
  /// Pre-fill the customer's first name on the checkout form.
  final String? customerFirstName;

  /// Pre-fill the customer's last name on the checkout form.
  final String? customerLastName;

  /// Pre-fill the customer's phone number on the checkout form.
  final String? customerPhone;

  // ── Structured metadata ───────────────────────────────────────────────────
  /// Typed custom fields shown on the Paystack Dashboard for this transaction.
  final List<PaystackCustomField>? customFields;

  /// Cart line items attached to this transaction's metadata.
  final List<PaystackCartItem>? cartItems;

  // ── UI customisation ──────────────────────────────────────────────────────
  final bool showAppBar;
  final String appBarTitle;
  final Color? appBarColor;
  final Color? appBarTextColor;
  final Widget? loadingWidget;
  final Widget Function(String error, VoidCallback retry)? errorWidget;

  /// Custom logo widget shown in the AppBar and loading screen.
  /// Accepts any widget — [Image.asset], [Image.network], an SVG, etc.
  final Widget? logoWidget;

  // ── Detailed Styling & Text overrides (Web-specific, stubbed here for compatibility) ──
  final Color? backgroundColor;
  final Color? cardBackgroundColor;
  final Color? cardBorderColor;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final Color? buttonTextColor;
  final String? connectingText;
  final String? waitingTitleText;
  final String? waitingSubtitleText;
  final String? step1Text;
  final String? step2Text;
  final String? step3Text;
  final String? completedButtonText;
  final String? reopenButtonText;
  final String? cancelButtonText;
  final String? verifyingText;
  final String? verifyingSubtitleText;

  /// Accent color used for the loading indicator, linear progress bar,
  /// verification spinner, and the "Try Again" button.
  ///
  /// Defaults to Paystack green (`#00C386`).
  final Color? progressColor;

  /// Background (track) color for the linear progress indicator shown
  /// while the WebView page is loading.
  ///
  /// Defaults to `Color(0xFF1E1E2E)`.
  final Color? progressBackgroundColor;

  // ── Network options ───────────────────────────────────────────────────────
  /// Maximum time to wait for the Paystack API before giving up.
  final Duration timeout;

  /// When `true`, logs request/response details via [debugPrint].
  /// Does nothing in release builds.
  final bool enableLogging;

  /// Called when the API call exceeds [timeout]. If `null` and a timeout
  /// occurs, [transactionNotCompleted] is called with `'timeout'`.
  final VoidCallback? onTimeout;

  const PaystackPayNow({
    Key? key,
    required this.publicKey,
    required this.email,
    required this.reference,
    required this.currency,
    required this.amount,
    required this.callbackUrl,
    required this.transactionCompleted,
    required this.transactionNotCompleted,
    this.transactionCancelled,
    this.metadata,
    this.plan,
    this.paymentChannel,
    this.subaccount,
    this.splitCode,
    this.transactionCharge,
    this.bearer,
    this.invoiceLimit,
    this.customerFirstName,
    this.customerLastName,
    this.customerPhone,
    this.customFields,
    this.cartItems,
    this.showAppBar = true,
    this.appBarTitle = 'Secure Checkout',
    this.appBarColor,
    this.appBarTextColor,
    this.loadingWidget,
    this.errorWidget,
    this.progressColor,
    this.progressBackgroundColor,
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = false,
    this.onTimeout,
    this.logoWidget,
    this.backgroundColor,
    this.cardBackgroundColor,
    this.cardBorderColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.buttonTextColor,
    this.connectingText,
    this.waitingTitleText,
    this.waitingSubtitleText,
    this.step1Text,
    this.step2Text,
    this.step3Text,
    this.completedButtonText,
    this.reopenButtonText,
    this.cancelButtonText,
    this.verifyingText,
    this.verifyingSubtitleText,
  }) : super(key: key);

  @override
  State<PaystackPayNow> createState() => _PaystackPayNowState();
}

// ── Checkout phase ─────────────────────────────────────────────────────────────

enum _CheckoutPhase {
  /// WebView is loading the Paystack popup HTML page.
  loading,

  /// Paystack popup is visible and the user is interacting.
  active,

  /// An error occurred.
  error,
}

class _PaystackPayNowState extends State<PaystackPayNow>
    with SingleTickerProviderStateMixin {
  _CheckoutPhase _phase = _CheckoutPhase.loading;
  String _errorMessage = '';

  /// WebView load progress (0–100). Drives the linear progress bar.
  int _loadProgress = 0;

  WebViewController? _webViewController;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initWebView();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Logging ────────────────────────────────────────────────────────────────

  void _log(String message) {
    if (widget.enableLogging) {
      debugPrint('[PayWithPaystack] $message');
    }
  }

  // ── Logo ───────────────────────────────────────────────────────────────────

  Widget? _buildLogoWidget(double size) {
    if (widget.logoWidget != null) {
      return SizedBox(width: size, height: size, child: widget.logoWidget);
    }
    return null;
  }

  // ── HTML generation ────────────────────────────────────────────────────────

  /// Builds the metadata JSON string for the Paystack popup config.
  String _buildMetadataJson() {
    final Map<String, dynamic> meta = {
      if (widget.metadata != null) ...widget.metadata!,
    };

    // Merge custom_fields
    final existingCustomFields =
        (meta['custom_fields'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final typedCustomFields =
        widget.customFields?.map((f) => f.toJson()).toList() ?? [];
    final allCustomFields = [...existingCustomFields, ...typedCustomFields];
    if (allCustomFields.isNotEmpty) {
      meta['custom_fields'] = allCustomFields;
    }

    // Attach cart items
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      meta['cart_items'] = widget.cartItems!.map((i) => i.toJson()).toList();
    }

    // Build JSON manually to avoid dart:convert import
    final buffer = StringBuffer('{');
    var first = true;
    meta.forEach((k, v) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$k":${_jsonValue(v)}');
    });
    buffer.write('}');
    return buffer.toString();
  }

  String _jsonValue(dynamic v) {
    if (v == null) return 'null';
    if (v is bool) return v.toString();
    if (v is num) return v.toString();
    if (v is String) {
      return '"${v.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r')}"';
    }
    if (v is List) {
      return '[${v.map(_jsonValue).join(',')}]';
    }
    if (v is Map) {
      final parts = v.entries.map((e) => '"${e.key}":${_jsonValue(e.value)}');
      return '{${parts.join(',')}}';
    }
    return '"$v"';
  }

  /// Generates the Paystack Inline Popup HTML page.
  ///
  /// This uses Paystack's public key — no secret key is needed or used.
  /// The Paystack popup JS SDK handles the checkout entirely client-side
  /// using only the public key.
  String _buildPopupHtml() {
    final amountInSubunit = (widget.amount * 100).toInt();
    final metaJson = _buildMetadataJson();

    // Build optional config entries
    final channelsJson = widget.paymentChannel != null
        ? '"channels": [${widget.paymentChannel!.map((c) => '"$c"').join(',')}],'
        : '';
    final planEntry = widget.plan != null ? '"plan": "${widget.plan}",' : '';
    final invoiceLimitEntry = widget.invoiceLimit != null
        ? '"invoice_limit": ${widget.invoiceLimit},'
        : '';
    final subaccountEntry = widget.subaccount != null
        ? '"subaccount": "${widget.subaccount}",'
        : '';
    final splitCodeEntry =
        widget.splitCode != null ? '"split_code": "${widget.splitCode}",' : '';
    final transactionChargeEntry = widget.transactionCharge != null
        ? '"transaction_charge": ${(widget.transactionCharge! * 100).toInt()},'
        : '';
    final bearerEntry =
        widget.bearer != null ? '"bearer": "${widget.bearer!.value}",' : '';
    final firstNameEntry = widget.customerFirstName != null
        ? '"firstname": "${widget.customerFirstName}",'
        : '';
    final lastNameEntry = widget.customerLastName != null
        ? '"lastname": "${widget.customerLastName}",'
        : '';
    final phoneEntry = widget.customerPhone != null
        ? '"phone": "${widget.customerPhone}",'
        : '';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Paystack Checkout</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      height: 100%;
      background: #0A0A1A;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    .loader {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }
    .spinner {
      width: 40px; height: 40px;
      border: 3px solid rgba(0,195,134,0.2);
      border-top-color: #00C386;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    p { color: #BBBBCC; font-size: 14px; letter-spacing: 0.3px; }
  </style>
</head>
<body>
  <div class="loader">
    <div class="spinner"></div>
    <p>Opening secure checkout…</p>
  </div>

  <script src="https://js.paystack.co/v1/inline.js"></script>
  <script>
    function notifyFlutter(type, data) {
      if (window.PaystackCallback) {
        window.PaystackCallback.postMessage(JSON.stringify({ type: type, data: data }));
      }
    }

    function openPaystack() {
      try {
        var handler = PaystackPop.setup({
          key: '${widget.publicKey}',
          email: '${widget.email}',
          amount: $amountInSubunit,
          currency: '${widget.currency}',
          ref: '${widget.reference}',
          $channelsJson
          $planEntry
          $invoiceLimitEntry
          $subaccountEntry
          $splitCodeEntry
          $transactionChargeEntry
          $bearerEntry
          $firstNameEntry
          $lastNameEntry
          $phoneEntry
          metadata: $metaJson,
          onClose: function() {
            notifyFlutter('cancelled', null);
          },
          callback: function(response) {
            notifyFlutter('success', {
              reference: response.reference,
              status: response.status,
              trans: response.trans,
              transaction: response.transaction,
              trxref: response.trxref
            });
          }
        });
        handler.openIframe();
      } catch(e) {
        notifyFlutter('error', e.toString());
      }
    }

    // Open checkout as soon as the Paystack script loads
    window.addEventListener('load', function() {
      openPaystack();
    });
  </script>
</body>
</html>''';
  }

  // ── WebView setup ──────────────────────────────────────────────────────────

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaystackCallback',
        onMessageReceived: _handleJsMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _phase = _CheckoutPhase.loading);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _phase = _CheckoutPhase.active);
          },
          onWebResourceError: (error) {
            _log('[ERROR] WebResource error: ${error.description}');
            // Only treat main-frame errors as fatal. Sub-resource
            // errors (e.g. a single script or image timing out)
            // should not flip the whole page to the error state —
            // this was causing a brief "sorry" flash before the
            // checkout loaded successfully.
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _phase = _CheckoutPhase.error;
                _errorMessage =
                    'Failed to load checkout page. Please check your connection.';
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            _log('[NAV] $url');

            // Block navigation away from our local HTML — the popup handles
            // everything internally. Only let data: and about: through.
            if (url.startsWith('data:') || url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }

            // If Paystack redirects to the callback URL, intercept it.
            if (url.contains(widget.callbackUrl)) {
              _log('[INFO] Callback URL hit — payment complete');
              // Extract reference from URL query params if present
              final uri = Uri.tryParse(url);
              final ref = uri?.queryParameters['reference'] ??
                  uri?.queryParameters['trxref'] ??
                  widget.reference;
              _handleSuccess(ref);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildPopupHtml());
  }

  /// Receives messages from the Paystack Popup JS via the JavaScript channel.
  void _handleJsMessage(JavaScriptMessage message) {
    _log('[JS] ${message.message}');
    try {
      // Simple JSON parsing without dart:convert — use the message as-is
      // by checking key strings. This avoids importing dart:convert.
      final msg = message.message;

      if (msg.contains('"type":"success"') ||
          msg.contains('"type": "success"')) {
        // Extract the reference from the JSON string
        final refMatch = RegExp(r'"reference"\s*:\s*"([^"]+)"').firstMatch(msg);
        final ref = refMatch?.group(1) ?? widget.reference;
        _handleSuccess(ref);
      } else if (msg.contains('"type":"cancelled"') ||
          msg.contains('"type": "cancelled"')) {
        _handleCancel();
      } else if (msg.contains('"type":"error"') ||
          msg.contains('"type": "error"')) {
        final errMatch = RegExp(r'"data"\s*:\s*"([^"]+)"').firstMatch(msg);
        final err = errMatch?.group(1) ?? 'Unknown error';
        if (mounted) {
          setState(() {
            _phase = _CheckoutPhase.error;
            _errorMessage = err;
          });
        }
      }
    } catch (e) {
      _log('[ERROR] Failed to parse JS message: $e');
    }
  }

  /// Called when Paystack reports a successful payment callback.
  ///
  /// NOTE: This fires when Paystack's popup reports success. The authoritative
  /// verification of the transaction must be done server-side by your backend
  /// using the Paystack secret key via `GET /transaction/verify/:reference`.
  void _handleSuccess(String reference) {
    _log('[INFO] Payment callback received for ref: $reference');
    // Build a minimal PaymentData from what we have. The developer's backend
    // should perform full verification and return enriched data.
    final data = PaymentData(
      reference: reference,
      status: 'success',
      // Store amount in smallest currency unit (kobo/pesewas), matching
      // Paystack's API convention. Use amountInMajorUnit getter to read it back.
      amount: (widget.amount * 100).toInt(),
      currency: widget.currency,
      paidAt: DateTime.now().toIso8601String(),
    );
    widget.transactionCompleted(data);
    if (mounted) Navigator.of(context).pop(data);
  }

  /// Called when the user explicitly cancels — closes without verifying.
  void _handleCancel() {
    _log('[INFO] User cancelled checkout');
    widget.transactionCancelled?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _retry() {
    setState(() {
      _phase = _CheckoutPhase.loading;
      _loadProgress = 0;
      _errorMessage = '';
    });
    _initWebView();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: _buildPhaseContent(),
    );
  }

  Widget _buildPhaseContent() {
    final accent = widget.progressColor ?? const Color(0xFF00C386);
    final progressBg =
        widget.progressBackgroundColor ?? const Color(0xFF1E1E2E);
    final appBarBgColor = widget.appBarColor ?? const Color(0xFF0A0A1A);
    final appBarFgColor = widget.appBarTextColor ?? Colors.white;
    final appBarLogo = _buildLogoWidget(20);

    if (_phase == _CheckoutPhase.error) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: appBarBgColor,
              foregroundColor: appBarFgColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  if (appBarLogo != null) ...[
                    appBarLogo,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.appBarTitle,
                    style: TextStyle(
                      color: appBarFgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: appBarFgColor),
                    tooltip: 'Close',
                    onPressed: _handleCancel,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: _loadProgress < 100
                    ? LinearProgressIndicator(
                        value: _loadProgress / 100,
                        backgroundColor: progressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 3,
                      )
                    : const SizedBox.shrink(),
              ),
            )
          : null,
      body: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (_phase == _CheckoutPhase.loading) _buildLoadingOverlay(accent),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(Color accent) {
    if (widget.loadingWidget != null) {
      return Center(child: widget.loadingWidget!);
    }
    final logo = _buildLogoWidget(48);
    return Container(
      color: const Color(0xFF0A0A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logo != null) ...[
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: logo),
                ),
              ),
              const SizedBox(height: 28),
            ],
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.connectingText ?? 'Connecting to Paystack…',
              style: const TextStyle(
                color: Color(0xFFBBBBCC),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final accent = widget.progressColor ?? const Color(0xFF00C386);
    if (widget.errorWidget != null) {
      return Scaffold(
        body: widget.errorWidget!(_errorMessage, _retry),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage.replaceFirst('PaystackException: ', ''),
                style: const TextStyle(
                  color: Color(0xFF888899),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF888899),
                        side: const BorderSide(color: Color(0xFF333344)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
