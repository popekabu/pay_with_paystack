library pay_with_paystack;

import 'package:flutter/material.dart';
import 'package:pay_with_paystack/src/paystack_pay_now.dart';

/// Main class, use the [now] method and provide arguments like;
/// secret [secretKey], [reference], [currency], [email], [email], [paymentChannel] and [amount].
class PayWithPayStack {
  Future<dynamic> now({
    /// Context provided from current view
    required BuildContext context,

    /// Secret key is provided from your paystack account
    required String secretKey,

    /// Email of the customer
    required String customerEmail,

    /// Alpha numeric and/or number ID to a transaction
    required String reference,

    /// callBack URL to handle redirection
    required String callbackUrl,

    /// Currency of the transaction
    required String currency,

    /// Amount you want to charge the user. Add extra two zeros after typing the amount
    required String amount,

    /// What happens next after transaction is completed
    required VoidCallback transactionCompleted,

    /// What happens next after transaction is not completed
    required VoidCallback transactionNotCompleted,

    /// Extra data not consumed by Paystack but for developer purposes
    Object? metaData,

    /// Payment Channels you want to make available to the user
    Object? paymentChannel,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaystackPayNow(
                secretKey: secretKey,
                email: customerEmail,
                reference: reference,
                currency: currency,
                amount: amount,
                paymentChannel: paymentChannel,
                metadata: metaData,
                transactionCompleted: transactionCompleted,
                transactionNotCompleted: transactionNotCompleted,
                callbackUrl: callbackUrl,
              )),
    );
  }
}
