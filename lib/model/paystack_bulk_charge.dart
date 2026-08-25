/// Represents a single item in a Paystack bulk charge batch.
///
/// Pass a list of these to [PayWithPayStack.bulkCharge] or to `POST /bulkcharge`
/// on the Paystack API to charge multiple authorizations in a single request.
///
/// ## Example
/// ```dart
/// final items = [
///   PaystackBulkChargeItem(
///     authorizationCode: 'AUTH_xxxxx',
///     amount: 50.00,
///     reference: PayWithPayStack().generateUuidV4(),
///     email: 'user1@example.com',
///   ),
///   PaystackBulkChargeItem(
///     authorizationCode: 'AUTH_yyyyy',
///     amount: 20.00,
///     reference: PayWithPayStack().generateUuidV4(),
///     email: 'user2@example.com',
///   ),
/// ];
///
/// final batch = await PayWithPayStack().bulkCharge(items: items);
/// ```
class PaystackBulkChargeItem {
  /// The authorization code from a previous successful transaction.
  /// Obtained from [PaymentData.authorization?.authorizationCode].
  final String authorizationCode;

  /// Amount to charge in the **major** currency unit (e.g. `50.00` for GHS 50).
  /// Converted to the subunit automatically in [toJson].
  final double amount;

  /// A unique reference for this charge in the batch.
  final String reference;

  /// The email address of the customer being charged (optional).
  final String? email;

  const PaystackBulkChargeItem({
    required this.authorizationCode,
    required this.amount,
    required this.reference,
    this.email,
  });

  /// Factory to construct a [PaystackBulkChargeItem] from a JSON map.
  factory PaystackBulkChargeItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    double parsedAmount = 0.0;
    if (rawAmount is num) {
      // If amount was in subunit, convert back to major unit
      parsedAmount = rawAmount.toDouble() / 100;
    } else if (rawAmount is String) {
      parsedAmount = (double.tryParse(rawAmount) ?? 0.0) / 100;
    }

    return PaystackBulkChargeItem(
      authorizationCode: json['authorization'] ?? json['authorization_code'] ?? '',
      amount: parsedAmount,
      reference: json['reference']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  /// Serialises this item to the JSON format expected by the Paystack
  /// `POST /bulkcharge` endpoint.
  ///
  /// The [amount] is converted from the major unit to the subunit
  /// (e.g. GHS 50.00 → 5000 pesewas).
  Map<String, dynamic> toJson() => {
        'authorization': authorizationCode,
        'amount': (amount * 100).toStringAsFixed(0),
        'reference': reference,
        if (email != null && email!.isNotEmpty) 'email': email,
      };

  @override
  String toString() =>
      'PaystackBulkChargeItem(auth: $authorizationCode, amount: $amount, ref: $reference, email: $email)';
}

/// Represents the status and summary of a Paystack bulk charge batch.
///
/// Returned by [PayWithPayStack.bulkCharge] and [PayWithPayStack.fetchBulkChargeBatch].
class PaystackBulkChargeBatch {
  /// The batch code identifier assigned by Paystack (e.g. `BCH_1878848492023`).
  final String? batchCode;

  /// The reference identifier for this batch.
  final String? reference;

  /// Current processing status (`pending`, `processing`, `complete`, `paused`, `failed`).
  final String? status;

  /// Total number of charges in the batch.
  final int? totalCharges;

  /// Number of charges still pending processing in this batch.
  final int? pendingCharges;

  /// Total processing units or charges count.
  final int? unit;

  /// Unique batch ID (when fetched via detail endpoint).
  final int? id;

  /// Paystack integration ID.
  final int? integration;

  /// Timestamp when the batch was created.
  final String? createdAt;

  /// Timestamp when the batch was last updated.
  final String? updatedAt;

  /// Raw response JSON from Paystack.
  final Map<String, dynamic> rawJson;

  const PaystackBulkChargeBatch({
    this.batchCode,
    this.reference,
    this.status,
    this.totalCharges,
    this.pendingCharges,
    this.unit,
    this.id,
    this.integration,
    this.createdAt,
    this.updatedAt,
    this.rawJson = const {},
  });

  /// Constructs a [PaystackBulkChargeBatch] from Paystack's response JSON map.
  factory PaystackBulkChargeBatch.fromJson(Map<String, dynamic> json) {
    return PaystackBulkChargeBatch(
      batchCode: json['batch_code']?.toString() ?? json['batchCode']?.toString(),
      reference: json['reference']?.toString(),
      status: json['status']?.toString(),
      totalCharges: json['total_charges'] is int
          ? json['total_charges'] as int
          : int.tryParse(json['total_charges']?.toString() ?? ''),
      pendingCharges: json['pending_charges'] is int
          ? json['pending_charges'] as int
          : int.tryParse(json['pending_charges']?.toString() ?? ''),
      unit: json['unit'] is int
          ? json['unit'] as int
          : int.tryParse(json['unit']?.toString() ?? ''),
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      integration: json['integration'] is int
          ? json['integration'] as int
          : int.tryParse(json['integration']?.toString() ?? ''),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      rawJson: json,
    );
  }

  /// Whether the batch is still pending initial processing.
  bool get isPending => status?.toLowerCase() == 'pending';

  /// Whether the batch is actively being processed by Paystack.
  bool get isProcessing => status?.toLowerCase() == 'processing';

  /// Whether the batch processing has finished completely.
  bool get isComplete =>
      status?.toLowerCase() == 'complete' ||
      status?.toLowerCase() == 'completed' ||
      status?.toLowerCase() == 'success';

  /// Whether the batch has been paused.
  bool get isPaused => status?.toLowerCase() == 'paused';

  /// Whether the batch has failed.
  bool get isFailed => status?.toLowerCase() == 'failed';

  /// Converts the batch data to a Map.
  Map<String, dynamic> toJson() => {
        if (batchCode != null) 'batch_code': batchCode,
        if (reference != null) 'reference': reference,
        if (status != null) 'status': status,
        if (totalCharges != null) 'total_charges': totalCharges,
        if (pendingCharges != null) 'pending_charges': pendingCharges,
        if (unit != null) 'unit': unit,
        if (id != null) 'id': id,
        if (integration != null) 'integration': integration,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  @override
  String toString() =>
      'PaystackBulkChargeBatch(batchCode: $batchCode, status: $status, total: $totalCharges, pending: $pendingCharges)';
}
