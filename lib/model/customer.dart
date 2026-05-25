/// Represents the customer details returned by Paystack after a transaction.
class Customer {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? customerCode;
  final String? phone;
  final Map<String, dynamic>? metadata;

  const Customer({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.customerCode,
    this.phone,
    this.metadata,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      customerCode: json['customer_code']?.toString(),
      phone: json['phone']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
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
      'metadata': metadata,
    };
  }

  /// Returns a copy of this [Customer] with the specified fields replaced.
  Customer copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? customerCode,
    String? phone,
    Map<String, dynamic>? metadata,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      customerCode: customerCode ?? this.customerCode,
      phone: phone ?? this.phone,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Returns the customer's full name, or `null` if both first and last name
  /// are unavailable.
  String? get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  String toString() {
    return 'Customer('
        'id: $id, '
        'firstName: $firstName, '
        'lastName: $lastName, '
        'email: $email, '
        'customerCode: $customerCode, '
        'phone: $phone'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.customerCode == customerCode &&
        other.phone == phone;
  }

  @override
  int get hashCode =>
      Object.hash(id, firstName, lastName, email, customerCode, phone);
}
