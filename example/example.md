```dart
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
        child: ElevatedButton(
          onPressed: () => _startPayment(context),
          child: const Text('Pay GHS 50.00'),
        ),
      ),
    );
  }

  Future<void> _startPayment(BuildContext context) async {
    // Generate a unique reference for this transaction
    final ref = PayWithPayStack().generateUuidV4();

    await PayWithPayStack().now(
      context: context,
      secretKey: 'sk_test_XXXXXXXXXXXXXXXXXXXXX', // Replace with your key
      customerEmail: 'user@example.com',
      reference: ref,
      currency: 'GHS',
      amount: 50.00, // GHS 50.00 — converted to pesewas automatically

      // Redirect URL — must match what's set in your Paystack dashboard
      callbackUrl: 'https://your-callback.com',

      // Restrict which payment options are shown (optional)
      channels: [
        PaystackChannel.card,
        PaystackChannel.mobileMoney,
        PaystackChannel.bankTransfer,
      ],

      // Extra data (optional)
      metadata: {
        'custom_fields': [
          {
            'display_name': 'Customer Name',
            'variable_name': 'customer_name',
            'value': 'Daniel Asare',
          },
        ],
      },

      // Optional UI customisation
      showAppBar: true,
      appBarTitle: 'Complete Payment',
      appBarColor: const Color(0xFF0A0A1A),
      appBarTextColor: Colors.white,

      // Called when transaction is successful
      transactionCompleted: (PaymentData data) {
        debugPrint('✅ Payment successful!');
        debugPrint('   Reference : ${data.reference}');
        debugPrint('   Amount    : ${data.amountInMajorUnit} ${data.currency}');
        debugPrint('   Channel   : ${data.channel}');
        debugPrint('   Customer  : ${data.customer?.fullName}');
        debugPrint('   Fees      : ${data.feesInMajorUnit} ${data.currency}');
        debugPrint('   Paid at   : ${data.paidAt}');
      },

      // Called when transaction is not successful
      transactionNotCompleted: (String reason) {
        debugPrint('❌ Payment not completed: $reason');
      },
    );
  }
}
```
