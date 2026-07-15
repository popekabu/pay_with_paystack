// ignore_for_file: use_build_context_synchronously
// This file is only compiled on Flutter Web (dart.library.html is available).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_bearer.dart';
import 'package:pay_with_paystack/model/paystack_metadata.dart';
import 'package:pay_with_paystack/model/paystack_request_response.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web-only checkout screen for `pay_with_paystack`.
///
/// On Flutter Web, `webview_flutter` is not supported. This widget provides
/// the equivalent experience:
///
/// 1. Calls `POST /transaction/initialize` to get the Paystack checkout URL.
/// 2. Opens that URL in a new browser tab via [url_launcher].
/// 3. Shows a responsive waiting UI while the user completes payment.
/// 4. On the user's confirmation, calls `GET /transaction/verify/:ref`.
/// 5. Fires [transactionCompleted] or [transactionNotCompleted] and pops.
///
/// The constructor signature is intentionally identical to `PaystackPayNow`
/// so that [PayWithPayStack.now] needs no platform branching.
///
/// The layout is responsive:
/// - **Wide screens (≥ 640 px)**: content centred in a max-width card.
/// - **Narrow screens (< 640 px)**: full-width, edge-to-edge layout.
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
  final VoidCallback? transactionCancelled;
  final String? subaccount;
  final String? splitCode;
  final double? transactionCharge;
  final PaystackBearer? bearer;
  final int? invoiceLimit;
  final String? customerFirstName;
  final String? customerLastName;
  final String? customerPhone;
  final List<PaystackCustomField>? customFields;
  final List<PaystackCartItem>? cartItems;
  final bool showAppBar;
  final String appBarTitle;
  final Color? appBarColor;
  final Color? appBarTextColor;
  final Widget? loadingWidget;
  final Widget Function(String error, VoidCallback retry)? errorWidget;

  final Widget? logoWidget;
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

  final Color? progressColor;
  final Color? progressBackgroundColor;
  final Duration timeout;
  final bool enableLogging;
  final VoidCallback? onTimeout;

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
  State<PaystackPayNow> createState() => _PaystackWebCheckoutState();
}

// ── States ────────────────────────────────────────────────────────────────────

enum _WebCheckoutPhase {
  /// Initialising transaction with Paystack API.
  initialising,

  /// Checkout URL has been opened in a new tab; waiting for user to return.
  waitingForPayment,

  /// Verifying the transaction with Paystack API.
  verifying,

  /// An unrecoverable error occurred.
  error,
}

// ── State ─────────────────────────────────────────────────────────────────────

class _PaystackWebCheckoutState extends State<PaystackPayNow>
    with SingleTickerProviderStateMixin {
  _WebCheckoutPhase _phase = _WebCheckoutPhase.initialising;
  String _errorMessage = '';
  PaystackRequestResponse? _response;

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

    _initialise();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Logging ─────────────────────────────────────────────────────────────────

  void _log(String msg) {
    if (widget.enableLogging) debugPrint('[PayWithPaystack/web] $msg');
  }

  // ── Logo ─────────────────────────────────────────────────────────────────

  /// Returns the caller-supplied logo, or `null` when [widget.logoWidget] was not provided.
  Widget? _buildLogoWidget(double size) {
    if (widget.logoWidget != null) {
      return SizedBox(width: size, height: size, child: widget.logoWidget);
    }
    return null;
  }


  // ── Network ─────────────────────────────────────────────────────────────────

  Future<void> _initialise() async {
    setState(() => _phase = _WebCheckoutPhase.initialising);

    final amountInSubunit = (widget.amount * 100).toStringAsFixed(0);

    final Map<String, dynamic> enrichedMetadata = {
      if (widget.metadata != null) ...widget.metadata!,
      'cancel_action': 'https://github.com/popekabu/pay_with_paystack',
    };

    final existingCustomFields =
        (enrichedMetadata['custom_fields'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final typedCustomFields =
        widget.customFields?.map((f) => f.toJson()).toList() ?? [];
    final allCustomFields = [...existingCustomFields, ...typedCustomFields];
    if (allCustomFields.isNotEmpty) {
      enrichedMetadata['custom_fields'] = allCustomFields;
    }

    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      enrichedMetadata['cart_items'] =
          widget.cartItems!.map((i) => i.toJson()).toList();
    }

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

    _log('→ POST /transaction/initialize');
    _log('  body: ${jsonEncode(requestBody)}');

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('https://api.paystack.co/transaction/initialize'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.secretKey}',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(widget.timeout, onTimeout: () {
        _log('[TIMEOUT] Request timed out after ${widget.timeout.inSeconds}s');
        if (widget.onTimeout != null) {
          widget.onTimeout!();
        } else {
          widget.transactionNotCompleted('timeout');
        }
        return http.Response(
          '{"status":false,"message":"Request timeout"}',
          408,
        );
      });
    } on Exception catch (e) {
      _log('[ERROR] $e');
      if (mounted) {
        setState(() {
          _phase = _WebCheckoutPhase.error;
          _errorMessage = 'Network error: ${e.toString()}';
        });
      }
      return;
    }

    _log('← ${response.statusCode} ${response.body}');

    if (!mounted) return;

    if (response.statusCode == 408) {
      setState(() {
        _phase = _WebCheckoutPhase.error;
        _errorMessage = 'Request timed out. Please check your connection.';
      });
      return;
    }

    if (response.statusCode == 200) {
      final parsed = PaystackRequestResponse.fromJson(
        jsonDecode(response.body),
      );
      if (parsed.status) {
        _response = parsed;
        await _openCheckoutTab(parsed.authUrl);
        return;
      }
    }

    setState(() {
      _phase = _WebCheckoutPhase.error;
      _errorMessage =
          'Failed to initialise payment (HTTP ${response.statusCode}).';
    });
  }

  Future<void> _openCheckoutTab(String url) async {
    _log('[INFO] Opening checkout tab: $url');
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _phase = _WebCheckoutPhase.waitingForPayment);
    } else {
      if (mounted) {
        setState(() {
          _phase = _WebCheckoutPhase.error;
          _errorMessage =
              'Could not open the Paystack checkout page. '
              'Please check your browser settings.';
        });
      }
    }
  }

  Future<void> _verifyTransaction() async {
    if (_response == null) return;
    setState(() => _phase = _WebCheckoutPhase.verifying);

    _log('→ GET /transaction/verify/${_response!.reference}');

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse(
              'https://api.paystack.co/transaction/verify/${_response!.reference}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.secretKey}',
            },
          )
          .timeout(widget.timeout);
    } on TimeoutException {
      _log('[TIMEOUT] Verification timed out');
      if (mounted) {
        setState(() => _phase = _WebCheckoutPhase.waitingForPayment);
        _showSnackBar(
          'Verification timed out. Please try again.',
        );
      }
      return;
    } on Exception catch (e) {
      _log('[ERROR] $e');
      if (mounted) {
        setState(() => _phase = _WebCheckoutPhase.waitingForPayment);
        _showSnackBar('Network error. Please check your connection.');
      }
      return;
    }

    _log('← ${response.statusCode} ${response.body}');

    if (!mounted) return;

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
        'Verification failed (${response.statusCode}). '
        'Please check your Paystack dashboard.',
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _handleCancel() {
    widget.transactionCancelled?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = widget.progressColor ?? const Color(0xFF00C386);
    final appBarBg = widget.appBarColor ?? const Color(0xFF0A0A1A);
    final appBarFg = widget.appBarTextColor ?? Colors.white;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? const Color(0xFF07071A),
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: appBarBg,
                foregroundColor: appBarFg,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    if (_buildLogoWidget(20) case final appBarLogo?) ...[
                      appBarLogo,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.appBarTitle,
                      style: TextStyle(
                        color: appBarFg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (_phase != _WebCheckoutPhase.verifying)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: appBarFg),
                        tooltip: 'Cancel',
                        onPressed: _handleCancel,
                      ),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child:
                      _phase == _WebCheckoutPhase.initialising ||
                           _phase == _WebCheckoutPhase.verifying
                      ? LinearProgressIndicator(
                          backgroundColor:
                              widget.progressBackgroundColor ??
                              const Color(0xFF1E1E2E),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 3,
                        )
                      : const SizedBox.shrink(),
                ),
              )
            : null,
        body: _buildBody(accent),
      ),
    );
  }

  Widget _buildBody(Color accent) {
    switch (_phase) {
      case _WebCheckoutPhase.initialising:
        return _buildInitialisingState(accent);
      case _WebCheckoutPhase.waitingForPayment:
        return _buildWaitingState(accent);
      case _WebCheckoutPhase.verifying:
        return _buildVerifyingState(accent);
      case _WebCheckoutPhase.error:
        return _buildErrorState(accent);
    }
  }

  // ── Initialising ────────────────────────────────────────────────────────────

  Widget _buildInitialisingState(Color accent) {
    if (widget.loadingWidget != null) {
      return Center(child: widget.loadingWidget!);
    }
    final logo = _buildLogoWidget(48);
    final cardBg = widget.cardBackgroundColor ?? const Color(0xFF0F0F24);
    final cardBorder = widget.cardBorderColor ?? const Color(0xFF1E1E38);

    return Center(
      child: _WebCard(
        backgroundColor: cardBg,
        borderColor: cardBorder,
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
              style: TextStyle(
                color: widget.secondaryTextColor ?? const Color(0xFFBBBBCC),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Waiting ─────────────────────────────────────────────────────────────────

  Widget _buildWaitingState(Color accent) {
    final formattedAmount =
        '${widget.currency} ${widget.amount.toStringAsFixed(2)}';
    final waitingLogo = _buildLogoWidget(36);
    final cardBg = widget.cardBackgroundColor ?? const Color(0xFF0F0F24);
    final cardBorder = widget.cardBorderColor ?? const Color(0xFF1E1E38);
    final primaryTextCol = widget.primaryTextColor ?? Colors.white;
    final secondaryTextCol = widget.secondaryTextColor ?? Colors.white70;

    return Center(
      child: _WebCard(
        backgroundColor: cardBg,
        borderColor: cardBorder,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            if (waitingLogo != null) ...[
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: waitingLogo),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Center(
              child: Text(
                widget.waitingTitleText ?? 'Complete your payment',
                style: TextStyle(
                  color: primaryTextCol,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.waitingSubtitleText ?? 'A Paystack checkout page has opened in a new tab.',
                style: TextStyle(
                  color: secondaryTextCol.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 28),

            // ── Payment summary card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? const Color(0xFF111128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Amount',
                    value: formattedAmount,
                    primaryColor: primaryTextCol,
                    secondaryColor: secondaryTextCol,
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Email',
                    value: widget.email,
                    primaryColor: primaryTextCol,
                    secondaryColor: secondaryTextCol,
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Reference',
                    value: widget.reference,
                    mono: true,
                    primaryColor: primaryTextCol,
                    secondaryColor: secondaryTextCol,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Steps ────────────────────────────────────────────────────────
            _StepItem(
              number: '1',
              accent: accent,
              text: widget.step1Text ?? 'Complete payment in the Paystack tab',
              textColor: secondaryTextCol,
            ),
            const SizedBox(height: 8),
            _StepItem(
              number: '2',
              accent: accent,
              text: widget.step2Text ?? 'Return to this tab when done',
              textColor: secondaryTextCol,
            ),
            const SizedBox(height: 8),
            _StepItem(
              number: '3',
              accent: accent,
              text: widget.step3Text ?? 'Tap "I\'ve completed payment" below',
              textColor: secondaryTextCol,
            ),

            const SizedBox(height: 28),

            // ── Primary action ───────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _verifyTransaction,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                widget.completedButtonText ?? 'I\'ve completed payment',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: widget.buttonTextColor ?? Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),

            // ── Reopen link ──────────────────────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: _response == null
                    ? null
                    : () => _openCheckoutTab(_response!.authUrl),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: accent.withValues(alpha: 0.8),
                ),
                label: Text(
                  widget.reopenButtonText ?? 'Reopen checkout tab',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Cancel ────────────────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: _handleCancel,
                child: Text(
                  widget.cancelButtonText ?? 'Cancel payment',
                  style: TextStyle(
                    color: secondaryTextCol.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Verifying ───────────────────────────────────────────────────────────────

  Widget _buildVerifyingState(Color accent) {
    final cardBg = widget.cardBackgroundColor ?? const Color(0xFF0F0F24);
    final cardBorder = widget.cardBorderColor ?? const Color(0xFF1E1E38);
    final primaryTextCol = widget.primaryTextColor ?? Colors.white;

    return Center(
      child: _WebCard(
        backgroundColor: cardBg,
        borderColor: cardBorder,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.verifyingText ?? 'Verifying transaction…',
              style: TextStyle(
                color: primaryTextCol,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.verifyingSubtitleText ?? 'Please wait while we confirm your payment with Paystack.',
              style: TextStyle(
                color: (widget.secondaryTextColor ?? Colors.white70).withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _buildErrorState(Color accent) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(_errorMessage, _initialise);
    }
    final cardBg = widget.cardBackgroundColor ?? const Color(0xFF0F0F24);
    final cardBorder = widget.cardBorderColor ?? const Color(0xFF1E1E38);
    final primaryTextCol = widget.primaryTextColor ?? Colors.white;
    final secondaryTextCol = widget.secondaryTextColor ?? const Color(0xFF888899);

    return Center(
      child: _WebCard(
        backgroundColor: cardBg,
        borderColor: cardBorder,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(
                  color: primaryTextCol,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _errorMessage.replaceFirst('PaystackException: ', ''),
                style: TextStyle(
                  color: secondaryTextCol,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextCol,
                      side: BorderSide(color: cardBorder),
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
                    onPressed: _initialise,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: widget.buttonTextColor ?? Colors.black,
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
    );
  }
}

// ── Responsive card wrapper ────────────────────────────────────────────────────

/// Centres its [child] in a max-width card on wide screens (≥ 640 px).
/// On narrow screens (mobile-width web or small windows) it renders
/// edge-to-edge with generous padding instead.
class _WebCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  const _WebCard({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 640;

    if (isWide) {
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 40),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    // Narrow / mobile-width web
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: child,
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final Color primaryColor;
  final Color secondaryColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.mono = false,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryColor.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
              letterSpacing: mono ? 0.5 : 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Step item ─────────────────────────────────────────────────────────────────

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final Color accent;
  final Color textColor;

  const _StepItem({
    required this.number,
    required this.text,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
