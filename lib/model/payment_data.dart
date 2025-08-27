import 'package:pay_with_paystack/model/authorization.dart';
import 'package:pay_with_paystack/model/customer.dart';

class PaymentData {
  final int? id;
  final String? domain;
  final String? status;
  final String? reference;
  final String? receiptNumber;
  final int? amount;
  final String? message;
  final String? gatewayResponse;
  final String? paidAt;
  final String? createdAt;
  final String? channel;
  final String? currency;
  final String? ipAddress;
  final int? fees;
  final dynamic feesSplit;
  final Authorization? authorization;
  final Customer? customer;

  PaymentData({
    this.id,
    this.domain,
    this.status,
    this.reference,
    this.receiptNumber,
    this.amount,
    this.message,
    this.gatewayResponse,
    this.paidAt,
    this.createdAt,
    this.channel,
    this.currency,
    this.ipAddress,
    this.fees,
    this.feesSplit,
    this.authorization,
    this.customer,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      domain: json['domain']?.toString(),
      status: json['status']?.toString(),
      reference: json['reference']?.toString(),
      receiptNumber: json['receipt_number']?.toString(),
      amount: json['amount'] is String
          ? int.tryParse(json['amount'])
          : json['amount'],
      message: json['message']?.toString(),
      gatewayResponse: json['gateway_response']?.toString(),
      paidAt: json['paid_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      channel: json['channel']?.toString(),
      currency: json['currency']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      fees: json['fees'] is String ? int.tryParse(json['fees']) : json['fees'],
      feesSplit: json['fees_split'],
      authorization: json['authorization'] != null
          ? Authorization.fromJson(json['authorization'])
          : null,
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
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
      'authorization': authorization?.toJson(),
      'customer': customer?.toJson(),
    };
  }
}
