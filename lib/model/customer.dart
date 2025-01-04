class Customer {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? customerCode;
  final String? phone;

  Customer({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.customerCode,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      customerCode: json['customer_code']?.toString(),
      phone: json['phone']?.toString(),
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
