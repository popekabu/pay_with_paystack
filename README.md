## Features

🎉 **Mobile Money** 🎉  
🎉 **VISA / Mastercard / Verve** 🎉  
🎉 **Bank** 🎉  
🎉 **Bank Transfer** 🎉  
🎉 **USSD** 🎉  
🎉 **QR** 🎉  
🎉 **EFT** 🎉  

---

## Getting Started

### Android

Update `android/app/build.gradle`:

```groovy
android {
    compileSdkVersion 34  // use latest

    defaultConfig {
        minSdkVersion 19
    }
}
```

### iOS

No extra configuration required.

---

## Basic Usage

```dart
import 'package:pay_with_paystack/pay_with_paystack.dart';

final ref = PayWithPayStack().generateUuidV4();

await PayWithPayStack().now(
  context: context,
  secretKey: 'sk_live_XXXXXXXXXXXXXXXXXXXXX',
  customerEmail: 'user@example.com',
  reference: ref,
  currency: 'GHS',
  amount: 50.00,          // GHS 50.00 — converted to pesewas automatically
  callbackUrl: 'https://your-callback.com',
  transactionCompleted: (PaymentData data) {
    print('✅ Paid ${data.amountInMajorUnit} ${data.currency}');
    print('   Reference : ${data.reference}');
    print('   Channel   : ${data.channel}');
    print('   Customer  : ${data.customer?.fullName}');
  },
  transactionNotCompleted: (String reason) {
    print('❌ Payment not completed: $reason');
  },
);
```

---

## Payment Channels (type-safe)

Use the `PaystackChannel` enum instead of raw strings:

```dart
channels: [
  PaystackChannel.card,
  PaystackChannel.mobileMoney,
  PaystackChannel.bankTransfer,
],
```

| Enum value                     | API string        |
|--------------------------------|-------------------|
| `PaystackChannel.card`         | `card`            |
| `PaystackChannel.bank`         | `bank`            |
| `PaystackChannel.ussd`         | `ussd`            |
| `PaystackChannel.qr`           | `qr`              |
| `PaystackChannel.mobileMoney`  | `mobile_money`    |
| `PaystackChannel.bankTransfer` | `bank_transfer`   |
| `PaystackChannel.eft`          | `eft`             |

---

## Customer Prefill

Pre-fill the customer's name and phone on the checkout form so they don't have
to type it themselves:

```dart
PayWithPayStack().now(
  // ...
  customerFirstName: 'Daniel',
  customerLastName: 'Asare',
  customerPhone: '+233244000000',
);
```

These are automatically added as `custom_fields` in the transaction metadata so
they also appear on your Paystack Dashboard.

---

## Cart Items

Attach a typed list of cart line items to the transaction. These appear in the
transaction metadata on your Paystack Dashboard:

```dart
PayWithPayStack().now(
  // ...
  cartItems: [
    PaystackCartItem(name: 'Wireless Headphones', amount: 15.00, quantity: 1),
    PaystackCartItem(name: 'Phone Case', amount: 2.50, quantity: 2),
    PaystackCartItem(name: 'Charging Cable', amount: 5.00),
  ],
);
```

> Amounts are in the **major** currency unit (e.g. GHS 15.00). The plugin
> converts to pesewas / kobo automatically.

---

## Custom Fields (Dashboard-visible)

Add custom fields that appear on the Paystack Dashboard when viewing the
transaction:

```dart
PayWithPayStack().now(
  // ...
  customFields: [
    PaystackCustomField(
      displayName: 'Order ID',
      variableName: 'order_id',
      value: '#ORD-1234',
    ),
    PaystackCustomField(
      displayName: 'Delivery Zone',
      variableName: 'delivery_zone',
      value: 'Accra Central',
    ),
  ],
);
```

---

## Split Payments

Route a portion of a payment to a subaccount or a pre-defined split group.

### Subaccount split

```dart
PayWithPayStack().now(
  // ...
  subaccount: 'ACCT_xxxxxxxxxx',   // your subaccount code
  bearer: PaystackBearer.account,  // main account bears fees (default)
);
```

### Flat fee override

```dart
PayWithPayStack().now(
  // ...
  subaccount: 'ACCT_xxxxxxxxxx',
  transactionCharge: 5.00,          // GHS 5.00 flat fee goes to main account
  bearer: PaystackBearer.subaccount, // subaccount bears Paystack fees
);
```

### Pre-defined split group

```dart
PayWithPayStack().now(
  // ...
  splitCode: 'SPL_xxxxxxxxxx',
);
```

| Parameter           | Type               | Description |
|---------------------|--------------------|-------------|
| `subaccount`        | `String?`          | Subaccount code (`ACCT_xxx`) to split payment |
| `splitCode`         | `String?`          | Pre-defined split group code (`SPL_xxx`) |
| `transactionCharge` | `double?`          | Flat fee (major unit) for main account |
| `bearer`            | `PaystackBearer?`  | Who bears Paystack fees |

---

## Subscriptions

```dart
PayWithPayStack().now(
  // ...
  plan: 'PLN_xxxxxxxxxx',
  invoiceLimit: 12,  // charge 12 times then stop
);
```

---

## Customising the Checkout UI

```dart
PayWithPayStack().now(
  // ...
  showAppBar: true,
  appBarTitle: 'Pay Now',
  appBarColor: const Color(0xFF0A0A1A),
  appBarTextColor: Colors.white,

  // Custom loading screen (replaces default pulsing loader)
  loadingWidget: const Center(
    child: CircularProgressIndicator(color: Colors.green),
  ),

  // Custom error screen with retry
  errorWidget: (String error, VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(error),
        ElevatedButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  ),
);
```

---

## Raw Metadata

Attach any extra key-value data to the transaction:

```dart
metadata: {
  'cart_id': '12345',
  'custom_fields': [
    {
      'display_name': 'Promo Code',
      'variable_name': 'promo_code',
      'value': 'SAVE10',
    },
  ],
},
```

---

## Full Parameter Reference

| Parameter               | Type                                     | Required | Default              |
|-------------------------|------------------------------------------|----------|----------------------|
| `context`               | `BuildContext`                           | ✅       | —                    |
| `secretKey`             | `String`                                 | ✅       | —                    |
| `customerEmail`         | `String`                                 | ✅       | —                    |
| `reference`             | `String`                                 | ✅       | —                    |
| `callbackUrl`           | `String`                                 | ✅       | —                    |
| `currency`              | `String`                                 | ✅       | —                    |
| `amount`                | `double`                                 | ✅       | —                    |
| `transactionCompleted`  | `Function(PaymentData)`                  | ✅       | —                    |
| `transactionNotCompleted` | `Function(String)`                     | ✅       | —                    |
| `channels`              | `List<PaystackChannel>?`                 | ❌       | all channels         |
| `plan`                  | `String?`                                | ❌       | `null`               |
| `invoiceLimit`          | `int?`                                   | ❌       | `null`               |
| `subaccount`            | `String?`                                | ❌       | `null`               |
| `splitCode`             | `String?`                                | ❌       | `null`               |
| `transactionCharge`     | `double?`                                | ❌       | `null`               |
| `bearer`                | `PaystackBearer?`                        | ❌       | `null`               |
| `customerFirstName`     | `String?`                                | ❌       | `null`               |
| `customerLastName`      | `String?`                                | ❌       | `null`               |
| `customerPhone`         | `String?`                                | ❌       | `null`               |
| `customFields`          | `List<PaystackCustomField>?`             | ❌       | `null`               |
| `cartItems`             | `List<PaystackCartItem>?`                | ❌       | `null`               |
| `metadata`              | `Map<String, dynamic>?`                  | ❌       | `null`               |
| `showAppBar`            | `bool`                                   | ❌       | `true`               |
| `appBarTitle`           | `String`                                 | ❌       | `"Secure Checkout"`  |
| `appBarColor`           | `Color?`                                 | ❌       | dark theme default   |
| `appBarTextColor`       | `Color?`                                 | ❌       | `Colors.white`       |
| `loadingWidget`         | `Widget?`                                | ❌       | branded loader       |
| `errorWidget`           | `Widget Function(String, VoidCallback)?` | ❌       | branded error UI     |

---

## PaymentData Reference

| Field               | Type             | Description |
|---------------------|------------------|-------------|
| `id`                | `int?`           | Transaction ID |
| `status`            | `String?`        | `"success"`, `"failed"`, etc. |
| `reference`         | `String?`        | Transaction reference |
| `amount`            | `int?`           | Amount in smallest unit |
| `requestedAmount`   | `int?`           | Originally requested amount |
| `currency`          | `String?`        | Currency code |
| `channel`           | `String?`        | Payment channel used |
| `fees`              | `int?`           | Fees in smallest unit |
| `paidAt`            | `String?`        | Payment timestamp |
| `gatewayResponse`   | `String?`        | Gateway message |
| `customer`          | `Customer?`      | Customer details |
| `authorization`     | `Authorization?` | Card/auth details |
| `isSuccessful`      | `bool`           | `status == "success"` |
| `amountInMajorUnit` | `double?`        | `amount / 100` |
| `feesInMajorUnit`   | `double?`        | `fees / 100` |

---

## Screenshots

<img alt="" src="https://user-images.githubusercontent.com/26738997/192014501-035de07d-1130-49b6-895c-32c3182676cf.png" width=300/> <img alt="" src="https://user-images.githubusercontent.com/26738997/192014543-82674864-2851-4b2b-9f92-be73aa370702.png" width=300/>
<img alt="" src="https://user-images.githubusercontent.com/26738997/192014596-0396ee68-febf-4bf9-8d74-30253c9c94fe.png" width=300/> <img alt="" src="https://user-images.githubusercontent.com/26738997/192014634-a74376f8-7e96-4842-a133-58196f146b61.png" width=300/>

---

## Additional Information

For bug reports and feature requests, open an issue on [GitHub](https://github.com/popekabu/pay_with_paystack/issues).

## 📝 Contributors

A big thank you to all contributors:

- @joelarmah
- @pat64j
- @keezysilencer
- @Princewil
- @richprince23
- @VhiktorBrown

Feel free to contribute — the project is open to the public!

## 📝 Contributing, 😞 Issues, and 🐛 Bug Reports

Submit a detailed report <a href="https://github.com/popekabu/pay_with_paystack/issues">here</a>.

## Support My Work 🙏🏽

Buy me a coffee: <a href="https://buymeacoffee.com/popekabu">here</a>. Thank you for your support!
