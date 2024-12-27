// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final void Function() transactionCompleted;
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
          "amount": amount.toString(),
          "reference": widget.reference,
          "currency": widget.currency,
          "plan": widget.plan,
          "metadata": widget.metadata,
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
  Future<PaymentData?> _checkTransactionStatus(String ref) async {
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
      print(decodedRespBody.toString());
      if (decodedRespBody["data"]["status"] == "success") {
        widget.transactionCompleted();
      } else {
        widget.transactionNotCompleted(
            decodedRespBody["data"]["status"].toString());
      }
        return PaymentData.fromJson(decodedRespBody["data"]);
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
                      if (request.url
                          .contains(' https://your-cancel-url.com')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://cancelurl.com')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://standard.paystack.co/close')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://paystack.co/close')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url.contains(widget.callbackUrl)) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      }
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(snapshot.data!.authUrl));
              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
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

class PaystackRequestResponse {
  final bool status;
  final String authUrl;
  final String reference;
  final PaymentData? data;

  const PaystackRequestResponse(
      {required this.authUrl, required this.status, required this.reference,this.data, });

  factory PaystackRequestResponse.fromJson(Map<String, dynamic> json) {
    return PaystackRequestResponse(
      status: json['status'],
      authUrl: json['data']["authorization_url"],
      reference: json['data']["reference"],
      data: json['data'] != null ? PaymentData.fromJson(json["data"]) : null,
    );
  }
}


// Added PaymentData model

/// PaymentData from Paystack API response
class PaymentData {
  final int id;
  final String domain;
  final String status;
  final String reference;
  final String receiptNumber;
  final int amount;
  final String? message;
  final String gatewayResponse;
  final String paidAt;
  final String createdAt;
  final String channel;
  final String currency;
  final String ipAddress;

  final int fees;
  final dynamic feesSplit;
  final Authorization authorization;
  final Customer customer;

  PaymentData({
    required this.id,
    required this.domain,
    required this.status,
    required this.reference,
    required this.receiptNumber,
    required this.amount,
    this.message,
    required this.gatewayResponse,
    required this.paidAt,
    required this.createdAt,
    required this.channel,
    required this.currency,
    required this.ipAddress,
    required this.fees,
    this.feesSplit,
    required this.authorization,
    required this.customer,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'],
      domain: json['domain'],
      status: json['status'],
      reference: json['reference'],
      receiptNumber: json['receipt_number'],
      amount: json['amount'],
      message: json['message'],
      gatewayResponse: json['gateway_response'],
      paidAt: json['paid_at'],
      createdAt: json['created_at'],
      channel: json['channel'],
      currency: json['currency'],
      ipAddress: json['ip_address'],
      fees: json['fees'],
      feesSplit: json['fees_split'],
      authorization: Authorization.fromJson(json['authorization']),
      customer: Customer.fromJson(json['customer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'status': status,
      'reference': reference,
      'receipt_number': receiptNumber,
      'amount': amount,
      'message': message,
      'gateway_response': gatewayResponse,
      'paid_at': paidAt,
      'created_at': createdAt,
      'channel': channel,
      'currency': currency,
      'ip_address': ipAddress,
      'fees': fees,
      'fees_split': feesSplit,
      'authorization': authorization.toJson(),
      'customer': customer.toJson(),
    };
  }
}



class Authorization {
  final String authorizationCode;
  final String bin;
  final String last4;
  final String channel;
  final String cardType;
  final String bank;
  final String countryCode;
  final String brand;
  final String? accountName;
  final String mobileMoneyNumber;

  Authorization({
    required this.authorizationCode,
    required this.bin,
    required this.last4,
    required this.channel,
    required this.cardType,
    required this.bank,
    required this.countryCode,
    required this.brand,
    this.accountName,
    required this.mobileMoneyNumber,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      authorizationCode: json['authorization_code'],
      bin: json['bin'],
      last4: json['last4'],
      channel: json['channel'],
      cardType: json['card_type'],
      bank: json['bank'],
      countryCode: json['country_code'],
      brand: json['brand'],
      accountName: json['account_name'],
      mobileMoneyNumber: json['mobile_money_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_code': authorizationCode,
      'bin': bin,
      'last4': last4,
      'channel': channel,
      'card_type': cardType,
      'bank': bank,
      'country_code': countryCode,
      'brand': brand,
      'account_name': accountName,
      'mobile_money_number': mobileMoneyNumber,
    };
  }
}

class Customer {
  final int id;
  final String? firstName;
  final String? lastName;
  final String email;
  final String customerCode;
  final String? phone;

  Customer({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    required this.customerCode,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      customerCode: json['customer_code'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'customer_code': customerCode,
      'phone': phone,
    };
  }
}

// Optional: Uncomment if you need the PaymentResponse class
/*
class PaymentResponse {
  final bool status;
  final String message;
  final PaymentData data;

  PaymentResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: json['status'],
      message: json['message'],
      data: PaymentData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}
*/