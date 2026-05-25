/// A typed exception thrown by the `pay_with_paystack` plugin when a
/// Paystack API request fails.
class PaystackException implements Exception {
  /// A human-readable error message.
  final String message;

  /// The HTTP status code returned by the Paystack API, if available.
  final int? statusCode;

  /// The raw response body returned by the Paystack API, if available.
  final String? responseBody;

  const PaystackException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    final parts = <String>['PaystackException: $message'];
    if (statusCode != null) parts.add('Status: $statusCode');
    if (responseBody != null) parts.add('Body: $responseBody');
    return parts.join(' | ');
  }
}
