import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

void main() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basic payment
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
  Future<void> _basicPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      secretKey: 'sk_test_XXXXXXXXXXXXXXXXXXXXX',
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      currency: 'GHS',
      amount: 50.00,
      callbackUrl: 'https://your-callback.com',
      transactionCompleted: (PaymentData data) {
        debugPrint('✅ Paid: ${data.amountInMajorUnit} ${data.currency}');
      },
      transactionNotCompleted: (String reason) {
        debugPrint('❌ Not completed: $reason');
      },
    );
  }

  // ── Example 2: Full-featured payment ───────────────────────────────────────
  Future<void> _fullFeaturedPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      secretKey: 'sk_test_XXXXXXXXXXXXXXXXXXXXX',
      customerEmail: 'daniel@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      currency: 'GHS',
      amount: 120.00,
      callbackUrl: 'https://your-callback.com',

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
        const PaystackCartItem(
            name: 'Wireless Headphones', amount: 80.00, quantity: 1),
        const PaystackCartItem(name: 'Phone Case', amount: 20.00, quantity: 2),
      ],

      // Custom fields visible on the Paystack Dashboard
      customFields: [
        const PaystackCustomField(
          displayName: 'Order ID',
          variableName: 'order_id',
          value: '#ORD-1234',
        ),
        const PaystackCustomField(
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
        debugPrint('✅ Payment successful!');
        debugPrint('   Reference : ${data.reference}');
        debugPrint('   Amount    : ${data.amountInMajorUnit} ${data.currency}');
        debugPrint('   Channel   : ${data.channel}');
        debugPrint('   Customer  : ${data.customer?.fullName}');
        debugPrint('   Fees      : ${data.feesInMajorUnit} ${data.currency}');
        debugPrint('   Reusable  : ${data.authorization?.reusable}');
      },

      transactionNotCompleted: (String reason) {
        debugPrint('❌ Payment not completed: $reason');
      },
    );
  }

  // ── Example 3: Split payment ────────────────────────────────────────────────
  Future<void> _splitPayment(BuildContext context) async {
    await PayWithPayStack().now(
      context: context,
      secretKey: 'sk_test_XXXXXXXXXXXXXXXXXXXXX',
      customerEmail: 'user@example.com',
      reference: PayWithPayStack().generateUuidV4(),
      currency: 'GHS',
      amount: 200.00,
      callbackUrl: 'https://your-callback.com',

      // Route to a subaccount; main account keeps GHS 20.00 flat fee
      subaccount: 'ACCT_xxxxxxxxxx',
      transactionCharge: 20.00,
      bearer: PaystackBearer.account, // main account bears Paystack fees

      transactionCompleted: (PaymentData data) {
        debugPrint('✅ Split payment done: ${data.reference}');
      },

      transactionNotCompleted: (String reason) {
        debugPrint('❌ Not completed: $reason');
      },
    );
  }
}
