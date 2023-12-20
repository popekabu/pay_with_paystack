## Features


🎉**Mobile Money**🎉

🎉**VISA**🎉

🎉**Bank**🎉

🎉**Bank Transfer**🎉

🎉**USSD**🎉

🎉**QR**🎉

🎉**EFT**🎉

## Getting started

Before you run, do the following in your `android/app/build.gradle`

Update your compileSDKVersion to latest

```
android {
    compileSdkVersion 32
    }
```

Update your minSDKVersion to 19

```
  defaultConfig {
        minSdkVersion 19
    }
```

## Usage

Simply call the `PayWithPayStack` class to start making payments with paystack. As simple as that

Example

```
 PayWithPayStack().now(
    context: context
    secretKey:
    "sk_live_XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    customerEmail: "popekabu@gmail.com",
    reference:
    DateTime.now().microsecondsSinceEpoch.toString(),
    callbackUrl: "setup in your paystack dashboard"
    currency: "GHS",
    paymentChannel:["mobile_money", "card"],
    amount: "20000",
    transactionCompleted: () {
        print("Transaction Successful");
    },
    transactionNotCompleted: () {
        print("Transaction Not Successful!");
    });
```

## Definitions

`context`
To aid in routing to screens 

`secretKey`
Provided by Paystack

`customerEmail`
Email address of the user/customer trying to make payment for receipt purpose

`reference`
Unique ID, usually alphanumeric and/or number, to recognise this particular transaction

`currency`
Currency user/customer should be charged in

`amount`
Amount or value user/customer should be charged

`callbackUrl`
URL to redirect to after payment is successful, this helps close the session. This is setup in the Dashboard of paystack and the same URL setup is then provided here by you again. **This is very important for successful or failed transactions**

`paymentChannels [Optional]`
Payment Channels are provided to you by Paystack and some may not be available based on your country and preferences set in your paystack dashboard. Example; `["card", "bank", "ussd", "qr", "mobile_money", "bank_transfer", "eft"]`

`transactionCompleted`
Execute a function when transaction is completed or is successful

`transactionNotCompleted`
Execute a function when transaction is not completed or is successful

`metadata [Optional]`
Extra data for development purposes. Example:

```
 "metadata": {
             "custom_fields": [
               {
                "name": "Daniel Kabu Asare",
                "phone": "+2330267268224"
               }
             ]
           }
```

## Screenshots

<img alt="" src="https://user-images.githubusercontent.com/26738997/192014501-035de07d-1130-49b6-895c-32c3182676cf.png" width= 300/> <img alt="" src="https://user-images.githubusercontent.com/26738997/192014543-82674864-2851-4b2b-9f92-be73aa370702.png" width= 300/>
<img alt="" src="https://user-images.githubusercontent.com/26738997/192014596-0396ee68-febf-4bf9-8d74-30253c9c94fe.png" width= 300/> <img alt="" src="https://user-images.githubusercontent.com/26738997/192014634-a74376f8-7e96-4842-a133-58196f146b61.png" width= 300/>

## Additional information

For more information and bug reports, Contact me on github `@popekabu`

## 📝 Contributing, 😞 Issues and 🐛 Bug Reports

The project is open to public contribution. Please feel very free to contribute. Experienced an issue or want to report a bug? Please, report it <a href="https://github.com/popekabu/pay_with_paystack/issues">here</a>. Remember to be as descriptive as possible.

## Thank you!!
Add the dependency to your Project here <https://pub.dev/packages/pay_with_paystack>
