// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/model/payment_data.dart';
import 'package:pay_with_paystack/model/paystack_request_response.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackPayNow extends StatefulWidget {
  final String secretKey;
  final String reference;
  final String callbackUrl;
  final String currency;
  final String email;
  final double amount;
  final String? plan;
  final metadata;
  final paymentChannel;
  final void Function(PaymentData data) transactionCompleted;
  final void Function(String reason) transactionNotCompleted;

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
  }) : super(key: key);

  @override
  State<PaystackPayNow> createState() => _PaystackPayNowState();
}

class _PaystackPayNowState extends State<PaystackPayNow> {
  /// Makes HTTP Request to Paystack for access to make payment.
  Future<PaystackRequestResponse> _makePaymentRequest() async {
    http.Response? response;
    final amount = widget.amount * 100;

    try {
      // We'll create a modified metadata object with cancel_action.
      // This implementation below allows the user to be able to Cancel Payment
      // directly from the Paystack Webview.
      Map<String, dynamic> enrichedMetadata;

      // Here, we check if metadata is already a Map,
      // we create one if it's null, or convert if needed
      if (widget.metadata == null) {
        enrichedMetadata = {
          "cancel_action": "https://github.com/popekabu/pay_with_paystack"
        };
      } else if (widget.metadata is Map) {
        // We clone the existing metadata and add the new field
        enrichedMetadata = Map<String, dynamic>.from(widget.metadata);
        enrichedMetadata["cancel_action"] =
            "https://github.com/popekabu/pay_with_paystack";
      } else {
        // If metadata is not a Map, convert it to a string representation
        // and include it as part of the metadata
        enrichedMetadata = {
          "data": widget.metadata.toString(),
          "cancel_action": "https://github.com/popekabu/pay_with_paystack"
        };
      }

      /// Sending Data to paystack.
      response = await http.post(
        /// Url to send data to
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },

        /// Data to send to the URL with enriched metadata(with cancel_action).
        body: jsonEncode({
          "email": widget.email,
          "amount": amount.toString(),
          "reference": widget.reference,
          "currency": widget.currency,
          "plan": widget.plan,
          "metadata": enrichedMetadata, // We use the enriched metadata here
          "callback_url": widget.callbackUrl,
          "channels": widget.paymentChannel
        }),
      );
    } on Exception catch (e) {
      /// In the event of an exception, take the user back and show a SnackBar error.
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        var snackBar =
            SnackBar(content: Text("Fatal error occurred, ${e.toString()}"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    if (response!.statusCode == 200) {
      return PaystackRequestResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          "Response Code: ${response.statusCode}, Response Body${response.body}");
    }
  }

  /// Checks for transaction status of current transaction before view closes.
  Future _checkTransactionStatus(String ref) async {
    http.Response? response;
    try {
      /// Getting data, passing [ref] as a value to the URL that is being requested.
      response = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$ref'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },
      );
    } on Exception catch (_) {
      /// In the event of an exception, take the user back and show a SnackBar error.
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        var snackBar = const SnackBar(
            content: Text("Fatal error occurred, Please check your internet"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
    if (response!.statusCode == 200) {
      var decodedRespBody = jsonDecode(response.body);
      // print(decodedRespBody.toString());
      if (decodedRespBody["data"]["status"] == "success") {
        final data = PaymentData.fromJson(decodedRespBody["data"]);
        widget.transactionCompleted(data);
      } else {
        widget.transactionNotCompleted(
            decodedRespBody["data"]["status"].toString());
      }
    } else {
      /// Anything else means there is an issue
      throw Exception(
          "Response Code: ${response.statusCode}, Response Body${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back gesture
      child: FutureBuilder<PaystackRequestResponse>(
          future: _makePaymentRequest(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.status == true) {
              final controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                // ..setUserAgent("Flutter;Webview")
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onNavigationRequest: (request) async {
                      final url = request.url;

                      switch (url) {
                        case 'https://your-cancel-url.com':
                        case 'https://cancelurl.com':
                        case 'https://standard.paystack.co/close':
                        case 'https://paystack.co/close':
                        case 'https://github.com/popekabu/pay_with_paystack':
                          await _checkTransactionStatus(
                                  snapshot.data!.reference)
                              .then((value) {
                            Navigator.of(context).pop();
                          });
                          break;

                        default:
                          if (url.contains(widget.callbackUrl)) {
                            await _checkTransactionStatus(
                                    snapshot.data!.reference)
                                .then((value) {
                              Navigator.of(context).pop();
                            });
                          }
                          break;
                      }

                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(snapshot.data!.authUrl));
              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  //TODO -> Now that the Cancel Payment works, you can remove this cancel icon.
                  actions: [
                    InkWell(
                        onTap: () async {
                          await _checkTransactionStatus(
                                  snapshot.data!.reference)
                              .then((value) {
                            Navigator.of(context).pop();
                          });
                        },
                        child: const Icon(Icons.close)),
                  ],
                ),
                body: WebViewWidget(
                  controller: controller,
                ),
              );
            }

            if (snapshot.hasError) {
              return Material(
                child: Center(
                  child: Text('${snapshot.error}'),
                ),
              );
            }

            return const Material(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }),
    );
  }
}
