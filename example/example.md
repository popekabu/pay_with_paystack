```
import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Paystack Payment'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  final uniqueTransRef = PayWithPayStack().generateUuidV4();

                  PayWithPayStack().now(
                      context: context,
                      secretKey:"sk_live_XXXXXXXXXXXXXXXXXXXXX",
                      customerEmail: "popekabu@gmail.com",
                      reference: uniqueTransRef,
                      currency: "GHS",
                      amount: 20000,
                      callbackUrl: "https://google.com",
                      transactionCompleted: (paymentData) {
                          debugPrint(paymentData.toString());
                      },
                      transactionNotCompleted: (reason) {
                        debugPrint("==> Transaction failed reason $reason");
                      });
                },
                child: const Text(
                  "Pay With PayStack",
                  style: TextStyle(fontSize: 23),
                ))
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
```
