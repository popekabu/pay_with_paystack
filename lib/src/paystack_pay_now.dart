// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

/// Make Paystack payments instantly provided you have you Paystack
/// secret [secretKey], [reference], [currency], [email], [email], [paymentChannel] and [amount].
class PaystackPayNow extends StatefulWidget {
  /// Secret Key is provided by Paystack when an account is created with PayStack.
  final String secretKey;

  /// Reference could be alpha numeric and or numeric sequencial character,
  /// could be a way to check trasancation from the backend.
  final String reference;

  /// Currency as at the time of publishing was either GHS or NGN
  /// PayStack is currently expanding in Africa so try using other currencies.
  final String currency;

  /// Email of the customer trying to make payment.
  final String email;

  /// Amount eg. 2000 means 20.00, 30000 means 300.00
  /// the extra 2 zeroes are the two decimal places.
  final String amount;

  /// MetaData helps with DevOps for sending custom
  /// fields to be consumed at the backend of frontend.
  final Object? metadata;

  /// Payment Channels are the types of payment methods
  /// you want to present to the user based on what Paystack
  /// provides with your secretkey.
  final Object? paymentChannel;

  /// If transacted was completed successfully.
  final void Function() transactionCompleted;

  /// If transacted was not completed at all.
  final void Function() transactionNotCompleted;

  const PaystackPayNow(
      {Key? key,
      required this.secretKey,
      required this.email,
      required this.reference,
      required this.currency,
      required this.amount,
      required this.transactionCompleted,
      required this.transactionNotCompleted,
      this.metadata,
      this.paymentChannel})
      : super(key: key);

  @override
  State<PaystackPayNow> createState() => _PaystackPayNowState();
}

class _PaystackPayNowState extends State<PaystackPayNow> {
  /// Makes HTTP Request to Paystack for access to make payment.
  Future<PaystackRequestResponse> _makePaymentRequest() async {
    var response;
    try {
      /// Sending Data to paystack.
      response = await http.post(
        /// Url to send data to
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },

        /// Data to send to the URL.
        body: jsonEncode({
          "email": widget.email,
          "amount": widget.amount,
          "reference": widget.reference,
          "currency": widget.currency,
          "metadata": widget.metadata,
          "channels": widget.paymentChannel
        }),
      );
    } on Exception catch (_) {
      /// In the event of an exception, take the user back and show a SnackBar error.
      Navigator.pop(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      var snackBar = const SnackBar(
          content: Text("Fatal error occurred, Please check your internet"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    if (response.statusCode == 200) {
      /// Response code 200 means OK.
      /// Send data to the POJO Class if 200.
      return PaystackRequestResponse.fromJson(jsonDecode(response.body));
    } else {
      /// Anything else means there is an issue.
      throw Exception(
          "Response Code: ${response.statusCode}, Response Body${response.body}");
    }
  }

  /// Checks for transaction status of current transaction before view closes.
  Future _checkTransactionStatus(String ref) async {
    var response;
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      var snackBar = const SnackBar(
          content: Text("Fatal error occurred, Please check your internet"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    if (response.statusCode == 200) {
      /// Response code 200 means OK.
      /// Send data to the POJO Class if 200.
      var decodedRespBody = jsonDecode(response.body);
      if (decodedRespBody["data"]["gateway_response"] == "Approved" ||
          decodedRespBody["data"]["gateway_response"] == "Successful") {
        widget.transactionCompleted();
      } else {
        widget.transactionNotCompleted();
      }
    } else {
      /// Anything else means there is an issue
      throw Exception(
          "Response Code: ${response.statusCode}, Response Body${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaystackRequestResponse>(
      future: _makePaymentRequest(),
      builder: (context, snapshot) {
        /// Show screen if snapshot has data and status is true.
        if (snapshot.hasData && snapshot.data!.status == true) {
          return Scaffold(
              // appBar: AppBar(
              //   leading: IconButton(
              //     icon: const Icon(Icons.close, color: Colors.black),
              //     onPressed: () async {
              //       /// Check transaction status before closing the view back to the previous screen.
              //       await _checkTransactionStatus(snapshot.data!.reference)
              //           .then((value) {
              //         return Navigator.of(context).pop();
              //       });
              //     },
              //   ),
              //   backgroundColor: Colors.white,
              // ),
              body: WebView(
            initialUrl: snapshot.data!.authUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (navigation) async {
              if (navigation.url == 'https://standard.paystack.co/close') {
                /// Check transaction status before closing the view back to the previous screen.
                await _checkTransactionStatus(snapshot.data!.reference)
                    .then((value) {
                  return Navigator.of(context).pop();
                });
              }
              return NavigationDecision.navigate;
            },
          ));
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Request Response POJO Class for recieving data
/// from the paystack API.
class PaystackRequestResponse {
  final bool status;
  final String authUrl;
  final String reference;

  const PaystackRequestResponse(
      {required this.authUrl, required this.status, required this.reference});

  factory PaystackRequestResponse.fromJson(Map<String, dynamic> json) {
    return PaystackRequestResponse(
      status: json['status'],
      authUrl: json['data']["authorization_url"],
      reference: json['data']["reference"],
    );
  }
}
