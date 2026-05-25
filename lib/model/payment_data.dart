import 'package:pay_with_paystack/model/authorization.dart';
import 'package:pay_with_paystack/model/customer.dart';

/// Represents the full payment data returned by Paystack after a transaction
/// is verified.
class PaymentData {
  final int? id;
  final String? domain;
  final String? status;
  final String? reference;
  final String? receiptNumber;

  /// Amount in the smallest currency unit (e.g. kobo for NGN, pesewas for GHS).
  final int? amount;

  /// Amount originally requested, in the smallest currency unit.
  final int? requestedAmount;

  final String? message;
  final String? gatewayResponse;
  final String? paidAt;
  final String? createdAt;
  final String? channel;
  final String? currency;
  final String? ipAddress;
  final String? orderId;

  /// Transaction fees, in the smallest currency unit.
  final int? fees;
  final dynamic feesSplit;
  final Authorization? authorization;
  final Customer? customer;

  const PaymentData({
    this.id,
    this.domain,
    this.status,
    this.reference,
    this.receiptNumber,
    this.amount,
    this.requestedAmount,
    this.message,
    this.gatewayResponse,
    this.paidAt,
    this.createdAt,
    this.channel,
    this.currency,
    this.ipAddress,
    this.orderId,
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
      requestedAmount: json['requested_amount'] is String
          ? int.tryParse(json['requested_amount'])
          : json['requested_amount'],
      message: json['message']?.toString(),
      gatewayResponse: json['gateway_response']?.toString(),
      paidAt: json['paid_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      channel: json['channel']?.toString(),
      currency: json['currency']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      orderId: json['order_id']?.toString(),
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
      'requested_amount': requestedAmount,
      'message': message,
      'gateway_response': gatewayResponse,
      'paid_at': paidAt,
      'created_at': createdAt,
      'channel': channel,
      'currency': currency,
      'ip_address': ipAddress,
      'order_id': orderId,
      'fees': fees,
      'fees_split': feesSplit,
      'authorization': authorization?.toJson(),
      'customer': customer?.toJson(),
    };
  }

  /// Returns a copy of this [PaymentData] with the specified fields replaced.
  PaymentData copyWith({
    int? id,
    String? domain,
    String? status,
    String? reference,
    String? receiptNumber,
    int? amount,
    int? requestedAmount,
    String? message,
    String? gatewayResponse,
    String? paidAt,
    String? createdAt,
    String? channel,
    String? currency,
    String? ipAddress,
    String? orderId,
    int? fees,
    dynamic feesSplit,
    Authorization? authorization,
    Customer? customer,
  }) {
    return PaymentData(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      amount: amount ?? this.amount,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      message: message ?? this.message,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      channel: channel ?? this.channel,
      currency: currency ?? this.currency,
      ipAddress: ipAddress ?? this.ipAddress,
      orderId: orderId ?? this.orderId,
      fees: fees ?? this.fees,
      feesSplit: feesSplit ?? this.feesSplit,
      authorization: authorization ?? this.authorization,
      customer: customer ?? this.customer,
    );
  }

  /// Whether this transaction was successful.
  bool get isSuccessful => status == 'success';

  /// The amount in the major currency unit (e.g. GHS, NGN).
  double? get amountInMajorUnit => amount != null ? amount! / 100.0 : null;

  /// The fees in the major currency unit.
  double? get feesInMajorUnit => fees != null ? fees! / 100.0 : null;

  @override
  String toString() {
    return 'PaymentData('
        'id: $id, '
        'status: $status, '
        'reference: $reference, '
        'amount: $amount, '
        'currency: $currency, '
        'channel: $channel, '
        'gatewayResponse: $gatewayResponse, '
        'paidAt: $paidAt, '
        'customer: $customer, '
        'authorization: $authorization'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentData &&
        other.id == id &&
        other.reference == reference &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, reference, status);
}
