// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_bearer.dart';
import 'package:pay_with_paystack/model/paystack_exception.dart';
import 'package:pay_with_paystack/model/paystack_metadata.dart';
import 'package:pay_with_paystack/model/paystack_request_response.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Internal widget that hosts the Paystack WebView checkout experience.
///
/// Use [PayWithPayStack.now] instead of instantiating this directly.
class PaystackPayNow extends StatefulWidget {
  final String secretKey;
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

  const PaystackPayNow({
    Key? key,
    required this.secretKey,
    required this.email,
    required this.reference,
    required this.currency,
    required this.amount,
    required this.callbackUrl,
    required this.transactionCompleted,
    required this.transactionNotCompleted,
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
  }) : super(key: key);

  @override
  State<PaystackPayNow> createState() => _PaystackPayNowState();
}

class _PaystackPayNowState extends State<PaystackPayNow>
    with SingleTickerProviderStateMixin {
  late Future<PaystackRequestResponse> _requestFuture;

  /// Whether we are currently verifying the transaction (overlay shown).
  bool _isVerifying = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _requestFuture = _makePaymentRequest();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Network ────────────────────────────────────────────────────────────────

  /// Initialises a Paystack transaction and returns the checkout URL.
  Future<PaystackRequestResponse> _makePaymentRequest() async {
    // Amount must be in the smallest currency unit (kobo / pesewas).
    final amountInSubunit = (widget.amount * 100).toStringAsFixed(0);

    // ── Build enriched metadata ────────────────────────────────────────────
    final Map<String, dynamic> enrichedMetadata = {
      if (widget.metadata != null) ...widget.metadata!,
      // Allows the WebView to detect when the user dismisses the checkout.
      'cancel_action': 'https://github.com/popekabu/pay_with_paystack',
    };

    // Merge typed custom_fields (preserve any already in metadata).
    final existingCustomFields =
        (enrichedMetadata['custom_fields'] as List?)?.cast<Map<String, dynamic>>()
            ?? [];
    final typedCustomFields =
        widget.customFields?.map((f) => f.toJson()).toList() ?? [];
    final allCustomFields = [...existingCustomFields, ...typedCustomFields];
    if (allCustomFields.isNotEmpty) {
      enrichedMetadata['custom_fields'] = allCustomFields;
    }

    // Attach cart items.
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      enrichedMetadata['cart_items'] =
          widget.cartItems!.map((i) => i.toJson()).toList();
    }

    // ── Build request body ─────────────────────────────────────────────────
    final requestBody = <String, dynamic>{
      'email': widget.email,
      'amount': amountInSubunit,
      'reference': widget.reference,
      'currency': widget.currency,
      'metadata': enrichedMetadata,
      'callback_url': widget.callbackUrl,
      if (widget.plan != null) 'plan': widget.plan,
      if (widget.invoiceLimit != null) 'invoice_limit': widget.invoiceLimit,
      if (widget.paymentChannel != null) 'channels': widget.paymentChannel,
      if (widget.subaccount != null) 'subaccount': widget.subaccount,
      if (widget.splitCode != null) 'split_code': widget.splitCode,
      if (widget.transactionCharge != null)
        'transaction_charge':
            (widget.transactionCharge! * 100).toStringAsFixed(0),
      if (widget.bearer != null) 'bearer': widget.bearer!.value,
    };

    http.Response response;
    try {
      response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },
        body: jsonEncode(requestBody),
      );
    } on Exception catch (e) {
      throw PaystackException(
        message: 'Network error: ${e.toString()}',
      );
    }

    if (response.statusCode == 200) {
      return PaystackRequestResponse.fromJson(jsonDecode(response.body));
    }

    throw PaystackException(
      message: 'Failed to initialise payment',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  /// Verifies the transaction status with Paystack and fires the appropriate
  /// callback, then pops the screen.
  Future<void> _checkTransactionStatus(String ref) async {
    if (!mounted) return;
    setState(() => _isVerifying = true);

    http.Response response;
    try {
      response = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$ref'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },
      );
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _isVerifying = false);
        _showSnackBar('Network error. Please check your connection.');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = decoded['data']?['status']?.toString();
      if (status == 'success') {
        final data = PaymentData.fromJson(decoded['data']);
        widget.transactionCompleted(data);
      } else {
        widget.transactionNotCompleted(status ?? 'unknown');
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      _showSnackBar(
        'Verification failed (${response.statusCode}). Please check your dashboard.',
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FutureBuilder<PaystackRequestResponse>(
        future: _requestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            final errorMsg = snapshot.error?.toString() ?? 'An error occurred';
            return _buildErrorState(errorMsg);
          }

          if (snapshot.hasData && snapshot.data!.status) {
            return _buildWebViewState(snapshot.data!);
          }

          // Fallback: unexpected data state
          return _buildErrorState('Unexpected response from Paystack.');
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    if (widget.loadingWidget != null) {
      return Scaffold(body: Center(child: widget.loadingWidget!));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C386).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: _PaystackLogo(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF00C386)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connecting to Paystack…',
              style: TextStyle(
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

  Widget _buildErrorState(String error) {
    if (widget.errorWidget != null) {
      return Scaffold(
        body: widget.errorWidget!(error, _retry),
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
                error.replaceFirst('PaystackException: ', ''),
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
                        backgroundColor: const Color(0xFF00C386),
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

  Widget _buildWebViewState(PaystackRequestResponse data) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final url = request.url;

            final isCancelUrl = const {
              'https://your-cancel-url.com',
              'https://cancelurl.com',
              'https://standard.paystack.co/close',
              'https://paystack.co/close',
              'https://github.com/popekabu/pay_with_paystack',
            }.contains(url);

            final isCallbackUrl = url.contains(widget.callbackUrl);

            if (isCancelUrl || isCallbackUrl) {
              await _checkTransactionStatus(data.reference);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(data.authUrl));

    final appBarBgColor =
        widget.appBarColor ?? const Color(0xFF0A0A1A);
    final appBarFgColor =
        widget.appBarTextColor ?? Colors.white;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0A0A1A),
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: appBarBgColor,
                  foregroundColor: appBarFgColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      const _PaystackLogo(size: 20),
                      const SizedBox(width: 10),
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
                        onPressed: () async {
                          await _checkTransactionStatus(data.reference);
                        },
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      color: const Color(0xFF1E1E2E),
                      height: 1,
                    ),
                  ),
                )
              : null,
          body: WebViewWidget(controller: controller),
        ),

        // Verification overlay
        if (_isVerifying)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: Color(0xFF1A1A2E),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00C386),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Verifying transaction…',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _retry() {
    setState(() {
      _requestFuture = _makePaymentRequest();
    });
  }
}

// ── Shared Paystack logo widget ─────────────────────────────────────────────

class _PaystackLogo extends StatelessWidget {
  final double size;
  const _PaystackLogo({this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C386)
      ..style = PaintingStyle.fill;

    // Draw a simple stylised "P" mark in the Paystack green
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.15)
      ..lineTo(size.width * 0.2, size.height * 0.85)
      ..lineTo(size.width * 0.38, size.height * 0.85)
      ..lineTo(size.width * 0.38, size.height * 0.58)
      ..quadraticBezierTo(
          size.width * 0.9, size.height * 0.55,
          size.width * 0.9, size.height * 0.36)
      ..quadraticBezierTo(
          size.width * 0.9, size.height * 0.15,
          size.width * 0.38, size.height * 0.15)
      ..close();

    canvas.drawPath(path, paint);

    // Inner cutout to form the "bowl" of the P
    final cutout = Paint()
      ..color = const Color(0xFF00C386).withValues(alpha: 0)
      ..blendMode = BlendMode.clear;
    final innerPath = Path()
      ..moveTo(size.width * 0.38, size.height * 0.27)
      ..lineTo(size.width * 0.72, size.height * 0.27)
      ..quadraticBezierTo(
          size.width * 0.78, size.height * 0.36,
          size.width * 0.72, size.height * 0.46)
      ..lineTo(size.width * 0.38, size.height * 0.46)
      ..close();

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(path, paint);
    canvas.drawPath(innerPath, cutout);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
