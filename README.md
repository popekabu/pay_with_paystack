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

## Usage

Import the package and call `PayWithPayStack().now(...)`:

```dart
import 'package:pay_with_paystack/pay_with_paystack.dart';

// Generate a unique reference for each transaction
final ref = PayWithPayStack().generateUuidV4();

await PayWithPayStack().now(
  context: context,
  secretKey: 'sk_live_XXXXXXXXXXXXXXXXXXXXX',
  customerEmail: 'user@example.com',
  reference: ref,
  currency: 'GHS',
  amount: 50.00,          // GHS 50.00  — converted to pesewas automatically
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

Use the `PaystackChannel` enum to restrict which payment options are shown:

```dart
channels: [
  PaystackChannel.card,
  PaystackChannel.mobileMoney,
  PaystackChannel.bankTransfer,
],
```

| Enum value                    | API string        |
|-------------------------------|-------------------|
| `PaystackChannel.card`        | `card`            |
| `PaystackChannel.bank`        | `bank`            |
| `PaystackChannel.ussd`        | `ussd`            |
| `PaystackChannel.qr`          | `qr`              |
| `PaystackChannel.mobileMoney` | `mobile_money`    |
| `PaystackChannel.bankTransfer`| `bank_transfer`   |
| `PaystackChannel.eft`         | `eft`             |

---

## Customising the Checkout UI

```dart
PayWithPayStack().now(
  // ... required params ...

  // AppBar
  showAppBar: true,
  appBarTitle: 'Pay Now',
  appBarColor: Color(0xFF0A0A1A),
  appBarTextColor: Colors.white,

  // Custom loading screen (optional — replaces the default pulsing loader)
  loadingWidget: const Center(
    child: CircularProgressIndicator(color: Colors.green),
  ),

  // Custom error screen with retry (optional)
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

## Metadata

Attach additional data to a transaction (not consumed by Paystack):

```dart
metadata: {
  'custom_fields': [
    {
      'display_name': 'Customer Name',
      'variable_name': 'customer_name',
      'value': 'Daniel Asare',
    },
  ],
},
```

---

## Parameter Reference

| Parameter               | Type                                          | Required | Default              | Description |
|-------------------------|-----------------------------------------------|----------|----------------------|-------------|
| `context`               | `BuildContext`                                | ✅       | —                    | Current context for navigation |
| `secretKey`             | `String`                                      | ✅       | —                    | Paystack secret key |
| `customerEmail`         | `String`                                      | ✅       | —                    | Customer's email |
| `reference`             | `String`                                      | ✅       | —                    | Unique transaction reference |
| `callbackUrl`           | `String`                                      | ✅       | —                    | Redirect URL (must match dashboard) |
| `currency`              | `String`                                      | ✅       | —                    | ISO 4217 currency code |
| `amount`                | `double`                                      | ✅       | —                    | Amount in major currency unit |
| `transactionCompleted`  | `Function(PaymentData)`                       | ✅       | —                    | Success callback |
| `transactionNotCompleted` | `Function(String)`                          | ✅       | —                    | Failure callback |
| `channels`              | `List<PaystackChannel>?`                      | ❌       | all channels         | Restrict payment options |
| `plan`                  | `String?`                                     | ❌       | `null`               | Paystack subscription plan code |
| `metadata`              | `Map<String, dynamic>?`                       | ❌       | `null`               | Extra transaction data |
| `showAppBar`            | `bool`                                        | ❌       | `true`               | Show/hide the AppBar |
| `appBarTitle`           | `String`                                      | ❌       | `"Secure Checkout"`  | AppBar title |
| `appBarColor`           | `Color?`                                      | ❌       | dark theme default   | AppBar background color |
| `appBarTextColor`       | `Color?`                                      | ❌       | `Colors.white`       | AppBar text/icon color |
| `loadingWidget`         | `Widget?`                                     | ❌       | branded loader       | Custom loading UI |
| `errorWidget`           | `Widget Function(String, VoidCallback)?`      | ❌       | branded error UI     | Custom error UI with retry |

---

## PaymentData Fields

| Field               | Type            | Description |
|---------------------|-----------------|-------------|
| `id`                | `int?`          | Paystack transaction ID |
| `status`            | `String?`       | `"success"`, `"failed"`, etc. |
| `reference`         | `String?`       | Transaction reference |
| `amount`            | `int?`          | Amount in smallest unit (kobo/pesewas) |
| `requestedAmount`   | `int?`          | Originally requested amount |
| `currency`          | `String?`       | Currency code |
| `channel`           | `String?`       | Payment channel used |
| `fees`              | `int?`          | Fees in smallest unit |
| `paidAt`            | `String?`       | Payment timestamp |
| `gatewayResponse`   | `String?`       | Gateway message |
| `customer`          | `Customer?`     | Customer details |
| `authorization`     | `Authorization?`| Card/auth details |
| `isSuccessful`      | `bool`          | Helper: `status == "success"` |
| `amountInMajorUnit` | `double?`       | Helper: `amount / 100` |
| `feesInMajorUnit`   | `double?`       | Helper: `fees / 100` |

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

This project is open to public contributions. If you encounter any issues or want to report a bug, please submit a detailed report <a href="https://github.com/popekabu/pay_with_paystack/issues">here</a>.

## Support My Work 🙏🏽

Buy me a coffee: <a href="https://buymeacoffee.com/popekabu">here</a>. Thank you for your support!
