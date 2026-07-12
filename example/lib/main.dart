import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

void main() {
  // ── Set global defaults once ──────────────────────────────────────────────
  // secretKey / currency / callbackUrl are now optional on individual calls.
  PayWithPayStack.configure(PaystackConfig(
    secretKey: 'sk_test_XXXXXXXXXXXXXXXXXXXXX',
    currency: PaystackCurrency.ghs.value, // typed enum — no typos!
    callbackUrl: 'https://your-callback.com',
    enableLogging: kDebugMode, // only logs in debug builds
    timeout: const Duration(seconds: 30),
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paystack Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C386)),
        useMaterial3: true,
      ),
      home: const PaymentPage(),
    );
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay With Paystack')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Tier 1: Basic (uses global config for key/currency/callback) ─
              _SectionLabel('Tier 1 — Basic (global config)'),
              ElevatedButton(
                onPressed: () => _basicPayment(context),
                child: const Text('Basic Payment — GHS 50'),
              ),
              const SizedBox(height: 12),

              // ── Tier 1: With timeout + onTimeout ─────────────────────────────
              ElevatedButton(
                onPressed: () => _paymentWithTimeout(context),
                child: const Text('Payment with 5s Timeout'),
              ),
              const SizedBox(height: 24),

              // ── Tier 2: transactionCancelled callback ─────────────────────────
              _SectionLabel('Tier 2 — New callbacks & config'),
              ElevatedButton(
                onPressed: () => _paymentWithCancelCallback(context),
                child: const Text('Payment with Cancel Callback'),
              ),
              const SizedBox(height: 12),

              // ── Tier 2: Full-featured with imageUrl on cart items ─────────────
              ElevatedButton(
                onPressed: () => _fullFeaturedPayment(context),
                child: const Text('Full-Featured (cart imageUrl)'),
              ),
              const SizedBox(height: 12),

              // ── Tier 2: Split payment ─────────────────────────────────────────
              ElevatedButton(
                onPressed: () => _splitPayment(context),
                child: const Text('Split Payment'),
              ),
              const SizedBox(height: 24),

              // ── Tier 3: Charge authorization (no WebView) ─────────────────────
              _SectionLabel('Tier 3 — Charge Authorization'),
              ElevatedButton(
                onPressed: () => _chargeAuthorization(context),
                child: const Text('Charge Saved Card (silent)'),
              ),
              const SizedBox(height: 24),

              // ── Tier 3: PaystackCurrency enum ─────────────────────────────────
              _SectionLabel('Tier 3 — Typed Currency'),
              ElevatedButton(
                onPressed: () => _paymentWithTypedCurrency(context),
                child: const Text('Pay in NGN (typed currency)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ── Example 1: Basic — no key/currency/callbackUrl needed (from config) ───
  Future<void> _basicPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 50.00,
      transactionCompleted: (PaymentData data) {
        debugPrint('[OK] Paid: ${data.amountInMajorUnit} ${data.currency}');
        debugPrint('   Requested: ${data.requestedAmountInMajorUnit}'); // new getter
      },
      transactionNotCompleted: (String reason) {
        debugPrint('[FAIL] Not completed: $reason');
      },
    );
  }

  // ── Example 2: Timeout ─────────────────────────────────────────────────────
  Future<void> _paymentWithTimeout(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 50.00,

      // Override the global 30s with 5s for demo purposes
      timeout: const Duration(seconds: 5),

      // Custom timeout handler — distinct from a failed payment
      onTimeout: () {
        debugPrint('[TIMEOUT] Timed out — show a friendly message');
      },

      transactionCompleted: (data) => debugPrint('[OK] Paid: ${data.reference}'),
      transactionNotCompleted: (reason) => debugPrint('[FAIL] Failed: $reason'),
    );
  }

  // ── Example 3: Cancel callback ─────────────────────────────────────────────
  Future<void> _paymentWithCancelCallback(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 75.00,

      // NEW: fires ONLY when user explicitly closes without paying
      // (distinct from transactionNotCompleted which fires after a failed attempt)
      transactionCancelled: () {
        debugPrint('[CANCELLED] User cancelled — not a failed attempt');
      },

      transactionCompleted: (data) => debugPrint('[OK] Paid: ${data.reference}'),
      transactionNotCompleted: (reason) => debugPrint('[FAIL] Failed: $reason'),
    );
  }

  // ── Example 4: Full-featured with imageUrl on cart items ──────────────────
  Future<void> _fullFeaturedPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'daniel@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 120.00,
      channels: [
        PaystackChannel.card,
        PaystackChannel.mobileMoney,
        PaystackChannel.bankTransfer,
      ],
      customerFirstName: 'Daniel',
      customerLastName: 'Asare',
      customerPhone: '+233244000000',

      // NEW: imageUrl on cart items
      cartItems: [
        const PaystackCartItem(
          name: 'Wireless Headphones',
          amount: 80.00,
          quantity: 1,
          imageUrl: 'https://example.com/headphones.jpg',
        ),
        const PaystackCartItem(
          name: 'Phone Case',
          amount: 20.00,
          quantity: 2,
        ),
      ],
      customFields: [
        const PaystackCustomField(
          displayName: 'Order ID',
          variableName: 'order_id',
          value: '#ORD-1234',
        ),
      ],
      showAppBar: true,
      appBarTitle: 'Complete Your Order',
      appBarColor: const Color(0xFF0A0A1A),
      appBarTextColor: Colors.white,
      transactionCompleted: (PaymentData data) {
        debugPrint('[OK] Payment successful!');
        debugPrint('   Reference : ${data.reference}');
        debugPrint('   Amount    : ${data.amountInMajorUnit} ${data.currency}');
        debugPrint('   Requested : ${data.requestedAmountInMajorUnit}');
        debugPrint('   Channel   : ${data.channel}');
        debugPrint('   Reusable  : ${data.authorization?.reusable}');
      },
      transactionNotCompleted: (String reason) {
        debugPrint('[FAIL] Payment not completed: $reason');
      },
      transactionCancelled: () {
        debugPrint('[CANCELLED] User closed checkout');
      },
    );
  }

  // ── Example 5: Split payment ───────────────────────────────────────────────
  Future<void> _splitPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 200.00,
      subaccount: 'ACCT_xxxxxxxxxx',
      transactionCharge: 20.00,
      bearer: PaystackBearer.account,
      transactionCompleted: (data) =>
          debugPrint('[OK] Split payment done: ${data.reference}'),
      transactionNotCompleted: (reason) =>
          debugPrint('[FAIL] Not completed: $reason'),
    );
  }

  // ── Example 6: Charge authorization (no WebView) ──────────────────────────
  Future<void> _chargeAuthorization(BuildContext context) async {
    // In a real app, save authorizationCode from a previous PaymentData:
    // final code = previousPaymentData.authorization?.authorizationCode;
    const savedAuthCode = 'AUTH_xxxxxxxxxx'; // from a previous payment

    await PayWithPayStack().chargeAuthorization(
      authorizationCode: savedAuthCode,
      customerEmail: 'user@example.com',
      amount: 30.00,
      // secretKey and currency from global config — no need to repeat!
      reference: PayWithPayStack().generateUuidV4(),
      transactionCompleted: (data) {
        debugPrint('[OK] Silent charge succeeded: ${data.reference}');
        debugPrint('   Amount: ${data.amountInMajorUnit} ${data.currency}');
      },
      transactionNotCompleted: (reason) {
        debugPrint('[FAIL] Silent charge failed: $reason');
      },
    );
  }

  // ── Example 7: Typed currency enum ────────────────────────────────────────
  Future<void> _paymentWithTypedCurrency(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 1000.00,

      // PaystackCurrency enum — no typos, IDE autocomplete
      currency: PaystackCurrency.ngn.value,

      // Override callbackUrl just for this payment
      callbackUrl: 'https://your-callback.com',

      transactionCompleted: (data) =>
          debugPrint('[OK] NGN payment: ${data.amountInMajorUnit}'),
      transactionNotCompleted: (reason) => debugPrint('[FAIL] Failed: $reason'),
    );
  }
}
