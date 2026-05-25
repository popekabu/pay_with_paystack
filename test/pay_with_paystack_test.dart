import 'package:flutter_test/flutter_test.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

void main() {
  // ── UUID ───────────────────────────────────────────────────────────────────
  group('PayWithPayStack.generateUuidV4', () {
    test('returns a non-empty string', () {
      final uuid = PayWithPayStack().generateUuidV4();
      expect(uuid, isNotEmpty);
    });

    test('generates unique values on each call', () {
      final a = PayWithPayStack().generateUuidV4();
      final b = PayWithPayStack().generateUuidV4();
      expect(a, isNot(equals(b)));
    });

    test('matches UUID v4 format', () {
      final uuid = PayWithPayStack().generateUuidV4();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(uuid), isTrue,
          reason: 'Expected UUID v4 format, got: $uuid');
    });
  });

  // ── PaystackChannel ────────────────────────────────────────────────────────
  group('PaystackChannel', () {
    test('toStringList converts enum list to string list', () {
      final result = PaystackChannel.toStringList([
        PaystackChannel.card,
        PaystackChannel.mobileMoney,
        PaystackChannel.bankTransfer,
      ]);
      expect(result, ['card', 'mobile_money', 'bank_transfer']);
    });

    test('fromString returns correct channel', () {
      expect(PaystackChannel.fromString('card'), PaystackChannel.card);
      expect(PaystackChannel.fromString('mobile_money'),
          PaystackChannel.mobileMoney);
      expect(PaystackChannel.fromString('eft'), PaystackChannel.eft);
    });

    test('fromString returns null for unknown value', () {
      expect(PaystackChannel.fromString('unknown_channel'), isNull);
    });

    test('all channels have distinct string values', () {
      final values = PaystackChannel.values.map((c) => c.value).toList();
      expect(values.toSet().length, equals(values.length));
    });
  });

  // ── Authorization ──────────────────────────────────────────────────────────
  group('Authorization', () {
    final sampleJson = {
      'authorization_code': 'AUTH_abc123',
      'bin': '408408',
      'last4': '4081',
      'exp_month': '12',
      'exp_year': '2025',
      'channel': 'card',
      'card_type': 'visa debit',
      'bank': 'TEST BANK',
      'country_code': 'GH',
      'brand': 'visa',
      'reusable': true,
      'signature': 'SIG_abc',
      'account_name': null,
      'mobile_money_number': null,
    };

    test('fromJson parses all fields correctly', () {
      final auth = Authorization.fromJson(sampleJson);
      expect(auth.authorizationCode, 'AUTH_abc123');
      expect(auth.bin, '408408');
      expect(auth.last4, '4081');
      expect(auth.expMonth, '12');
      expect(auth.expYear, '2025');
      expect(auth.channel, 'card');
      expect(auth.cardType, 'visa debit');
      expect(auth.bank, 'TEST BANK');
      expect(auth.countryCode, 'GH');
      expect(auth.brand, 'visa');
      expect(auth.reusable, isTrue);
      expect(auth.signature, 'SIG_abc');
      expect(auth.accountName, isNull);
      expect(auth.mobileMoneyNumber, isNull);
    });

    test('toJson round-trips correctly', () {
      final auth = Authorization.fromJson(sampleJson);
      final json = auth.toJson();
      expect(json['authorization_code'], 'AUTH_abc123');
      expect(json['last4'], '4081');
      expect(json['reusable'], isTrue);
    });

    test('copyWith replaces only the specified fields', () {
      final auth = Authorization.fromJson(sampleJson);
      final copy = auth.copyWith(last4: '9999', reusable: false);
      expect(copy.last4, '9999');
      expect(copy.reusable, isFalse);
      expect(copy.bin, auth.bin); // unchanged
    });

    test('toString contains key fields', () {
      final auth = Authorization.fromJson(sampleJson);
      expect(auth.toString(), contains('AUTH_abc123'));
      expect(auth.toString(), contains('4081'));
    });

    test('equality holds for identical objects', () {
      final a = Authorization.fromJson(sampleJson);
      final b = Authorization.fromJson(sampleJson);
      expect(a, equals(b));
    });
  });

  // ── Customer ───────────────────────────────────────────────────────────────
  group('Customer', () {
    final sampleJson = {
      'id': 123,
      'first_name': 'Daniel',
      'last_name': 'Asare',
      'email': 'daniel@example.com',
      'customer_code': 'CUS_abc',
      'phone': '+233000000000',
      'metadata': null,
    };

    test('fromJson parses all fields correctly', () {
      final customer = Customer.fromJson(sampleJson);
      expect(customer.id, 123);
      expect(customer.firstName, 'Daniel');
      expect(customer.lastName, 'Asare');
      expect(customer.email, 'daniel@example.com');
      expect(customer.customerCode, 'CUS_abc');
      expect(customer.phone, '+233000000000');
    });

    test('fullName returns combined first + last name', () {
      final customer = Customer.fromJson(sampleJson);
      expect(customer.fullName, 'Daniel Asare');
    });

    test('fullName returns first name only when last name is null', () {
      final customer = Customer.fromJson({...sampleJson, 'last_name': null});
      expect(customer.fullName, 'Daniel');
    });

    test('fullName returns null when both names are null', () {
      final customer = Customer.fromJson(
          {...sampleJson, 'first_name': null, 'last_name': null});
      expect(customer.fullName, isNull);
    });

    test('copyWith replaces only specified fields', () {
      final customer = Customer.fromJson(sampleJson);
      final copy = customer.copyWith(firstName: 'Kwame');
      expect(copy.firstName, 'Kwame');
      expect(copy.lastName, customer.lastName);
    });

    test('id parsed correctly as int when provided as String', () {
      final customer = Customer.fromJson({...sampleJson, 'id': '456'});
      expect(customer.id, 456);
    });

    test('equality holds for identical objects', () {
      final a = Customer.fromJson(sampleJson);
      final b = Customer.fromJson(sampleJson);
      expect(a, equals(b));
    });
  });

  // ── PaymentData ────────────────────────────────────────────────────────────
  group('PaymentData', () {
    final sampleJson = {
      'id': 1001,
      'domain': 'test',
      'status': 'success',
      'reference': 'ref_abc123',
      'receipt_number': 'RCP_001',
      'amount': 5000,
      'requested_amount': 5000,
      'message': null,
      'gateway_response': 'Successful',
      'paid_at': '2024-01-01T00:00:00.000Z',
      'created_at': '2024-01-01T00:00:00.000Z',
      'channel': 'card',
      'currency': 'GHS',
      'ip_address': '127.0.0.1',
      'order_id': null,
      'fees': 75,
      'fees_split': null,
      'authorization': null,
      'customer': null,
    };

    test('fromJson parses all fields correctly', () {
      final data = PaymentData.fromJson(sampleJson);
      expect(data.id, 1001);
      expect(data.status, 'success');
      expect(data.reference, 'ref_abc123');
      expect(data.amount, 5000);
      expect(data.currency, 'GHS');
      expect(data.channel, 'card');
      expect(data.fees, 75);
    });

    test('isSuccessful is true when status is "success"', () {
      final data = PaymentData.fromJson(sampleJson);
      expect(data.isSuccessful, isTrue);
    });

    test('isSuccessful is false when status is not "success"', () {
      final data = PaymentData.fromJson({...sampleJson, 'status': 'failed'});
      expect(data.isSuccessful, isFalse);
    });

    test('amountInMajorUnit divides by 100', () {
      final data = PaymentData.fromJson(sampleJson);
      expect(data.amountInMajorUnit, closeTo(50.0, 0.001));
    });

    test('feesInMajorUnit divides by 100', () {
      final data = PaymentData.fromJson(sampleJson);
      expect(data.feesInMajorUnit, closeTo(0.75, 0.001));
    });

    test('toJson round-trips key fields', () {
      final data = PaymentData.fromJson(sampleJson);
      final json = data.toJson();
      expect(json['status'], 'success');
      expect(json['reference'], 'ref_abc123');
      expect(json['amount'], 5000);
    });

    test('copyWith replaces only specified fields', () {
      final data = PaymentData.fromJson(sampleJson);
      final copy = data.copyWith(status: 'failed', fees: 0);
      expect(copy.status, 'failed');
      expect(copy.fees, 0);
      expect(copy.reference, data.reference);
    });

    test('amount parsed correctly as int when provided as String', () {
      final data = PaymentData.fromJson({...sampleJson, 'amount': '5000'});
      expect(data.amount, 5000);
    });

    test('toString contains key fields', () {
      final data = PaymentData.fromJson(sampleJson);
      expect(data.toString(), contains('success'));
      expect(data.toString(), contains('ref_abc123'));
    });

    test('equality based on id, reference, and status', () {
      final a = PaymentData.fromJson(sampleJson);
      final b = PaymentData.fromJson(sampleJson);
      expect(a, equals(b));
    });
  });

  // ── PaystackException ──────────────────────────────────────────────────────
  group('PaystackException', () {
    test('toString includes message', () {
      const ex = PaystackException(message: 'Network error');
      expect(ex.toString(), contains('Network error'));
    });

    test('toString includes statusCode when present', () {
      const ex = PaystackException(message: 'Bad request', statusCode: 400);
      expect(ex.toString(), contains('400'));
    });

    test('toString includes responseBody when present', () {
      const ex = PaystackException(
          message: 'Error', responseBody: '{"error":"invalid key"}');
      expect(ex.toString(), contains('invalid key'));
    });
  });

  // ── PaystackBearer ─────────────────────────────────────────────────────────
  group('PaystackBearer', () {
    test('account has correct string value', () {
      expect(PaystackBearer.account.value, 'account');
    });

    test('subaccount has correct string value', () {
      expect(PaystackBearer.subaccount.value, 'subaccount');
    });

    test('all bearers have distinct string values', () {
      final values = PaystackBearer.values.map((b) => b.value).toList();
      expect(values.toSet().length, equals(values.length));
    });
  });

  // ── PaystackCustomField ────────────────────────────────────────────────────
  group('PaystackCustomField', () {
    const field = PaystackCustomField(
      displayName: 'Order ID',
      variableName: 'order_id',
      value: '#ORD-1234',
    );

    test('toJson produces correct keys', () {
      final json = field.toJson();
      expect(json['display_name'], 'Order ID');
      expect(json['variable_name'], 'order_id');
      expect(json['value'], '#ORD-1234');
    });

    test('toString is readable', () {
      expect(field.toString(), contains('Order ID'));
      expect(field.toString(), contains('#ORD-1234'));
    });
  });

  // ── PaystackCartItem ───────────────────────────────────────────────────────
  group('PaystackCartItem', () {
    const item = PaystackCartItem(
      name: 'Wireless Headphones',
      amount: 15.00, // GHS 15.00
      quantity: 2,
    );

    test('toJson produces correct keys', () {
      final json = item.toJson();
      expect(json['name'], 'Wireless Headphones');
      expect(json['quantity'], 2);
    });

    test('toJson converts amount to subunit string', () {
      final json = item.toJson();
      // 15.00 GHS → 1500 pesewas
      expect(json['amount'], '1500');
    });

    test('quantity defaults to 1', () {
      const singleItem = PaystackCartItem(name: 'Cap', amount: 5.00);
      expect(singleItem.quantity, 1);
    });

    test('toString is readable', () {
      expect(item.toString(), contains('Wireless Headphones'));
      expect(item.toString(), contains('2'));
    });

    test('fractional amounts convert correctly', () {
      const fractional = PaystackCartItem(name: 'Snack', amount: 1.50);
      final json = fractional.toJson();
      expect(json['amount'], '150');
    });
  });
}
