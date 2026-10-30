```dart
import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

void main() {
  // Optional: configure once at app startup so publicKey / currency /
  // callbackUrl don't need to be repeated on every call.
  PayWithPayStack.configure(PaystackConfig(
    publicKey: 'pk_test_XXXXXXXXXXXXXXXXXXXXX', // ← public key only (pk_…)
    currency: 'GHS',
    callbackUrl: 'https://your-backend.com/verify',
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 3, 105, 231)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basic payment (uses global config for publicKey/currency/callbackUrl)
            ElevatedButton(
              onPressed: () => _basicPayment(context),
              child: const Text('Basic Payment (GHS 50)'),
            ),
            const SizedBox(height: 12),

            // Full-featured payment
            ElevatedButton(
              onPressed: () => _fullFeaturedPayment(context),
              child: const Text('Full-Featured Payment'),
            ),
            const SizedBox(height: 12),

            // Split payment
            ElevatedButton(
              onPressed: () => _splitPayment(context),
              child: const Text('Split Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Example 1: Basic payment ────────────────────────────────────────────────
  // publicKey / currency / callbackUrl come from the global config above.
  Future<void> _basicPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 50.00,
      transactionCompleted: (PaymentData data) {
        debugPrint('[OK] Paid: ${data.amountInMajorUnit} ${data.currency}');
        // IMPORTANT: verify this transaction server-side using:
        //   GET https://api.paystack.co/transaction/verify/${data.reference}
        // with your SECRET key — never do this in the Flutter app.
      },
      transactionNotCompleted: (String reason) {
        debugPrint('[FAIL] Not completed: $reason');
      },
    );
  }

  // ── Example 2: Full-featured payment ───────────────────────────────────────
  Future<void> _fullFeaturedPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      publicKey: 'pk_test_XXXXXXXXXXXXXXXXXXXXX', // can override global config
      customerEmail: 'daniel@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      currency: 'GHS',
      amount: 120.00,
      callbackUrl: 'https://your-backend.com/verify',

      // Restrict payment channels
      channels: [
        PaystackChannel.card,
        PaystackChannel.mobileMoney,
        PaystackChannel.bankTransfer,
      ],

      // Pre-fill customer info on the checkout form
      customerFirstName: 'Daniel',
      customerLastName: 'Asare',
      customerPhone: '+233244000000',

      // Cart items (line items in metadata)
      cartItems: [
        PaystackCartItem(name: 'Wireless Headphones', amount: 80.00, quantity: 1),
        PaystackCartItem(name: 'Phone Case', amount: 20.00, quantity: 2),
      ],

      // Custom fields visible on the Paystack Dashboard
      customFields: [
        PaystackCustomField(
          displayName: 'Order ID',
          variableName: 'order_id',
          value: '#ORD-1234',
        ),
        PaystackCustomField(
          displayName: 'Delivery Zone',
          variableName: 'delivery_zone',
          value: 'Accra Central',
        ),
      ],

      // UI customisation
      showAppBar: true,
      appBarTitle: 'Complete Your Order',
      appBarColor: const Color(0xFF0A0A1A),
      appBarTextColor: Colors.white,

      transactionCompleted: (PaymentData data) {
        debugPrint('[OK] Payment callback received!');
        debugPrint('   Reference : ${data.reference}');
        debugPrint('   Amount    : ${data.amountInMajorUnit} ${data.currency}');
        // Verify server-side — your backend at callbackUrl receives the ref
        // and calls GET /transaction/verify/:ref with the secret key.
      },

      transactionNotCompleted: (String reason) {
        debugPrint('[FAIL] Payment not completed: $reason');
      },
    );
  }

  // ── Example 3: Split payment ────────────────────────────────────────────────
  Future<void> _splitPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      amount: 200.00,

      // Route to a subaccount; main account keeps GHS 20.00 flat fee
      subaccount: 'ACCT_xxxxxxxxxx',
      transactionCharge: 20.00,
      bearer: PaystackBearer.account, // main account bears Paystack fees

      transactionCompleted: (PaymentData data) {
        debugPrint('[OK] Split payment callback for: ${data.reference}');
      },

      transactionNotCompleted: (String reason) {
        debugPrint('[FAIL] Not completed: $reason');
      },
    );
  }
}
```
