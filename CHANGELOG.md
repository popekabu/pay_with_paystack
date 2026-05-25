## 1.1.0

### ✨ New Features
- **`PaystackChannel` enum** — type-safe channel selection instead of raw strings.
  Use `PaystackChannel.toStringList(channels)` or pass directly to `now(channels: [...])`.
- **`plan` parameter** — expose subscription plan codes through the public `now()` API.
- **`metadata` is now typed** — `Map<String, dynamic>?` instead of `dynamic`.
- **Customisable AppBar** — new `showAppBar`, `appBarTitle`, `appBarColor`, and `appBarTextColor` parameters.
- **Custom loading widget** — pass any widget via `loadingWidget` to replace the default loader.
- **Custom error widget** — pass a builder via `errorWidget` to render your own error screen.
- **Retry button** — the default error screen now shows a "Try Again" button to re-attempt initialisation.
- **Verification overlay** — a non-dismissible overlay is shown while the transaction is being verified, preventing accidental taps.
- **Branded loading & error UIs** — the default loading screen now features a pulsing Paystack-green logo animation.
- **`Authorization` new fields** — `expMonth`, `expYear`, `reusable`, `signature`.
- **`Customer` new fields** — `metadata`, computed `fullName` getter.
- **`PaymentData` new fields** — `requestedAmount`, `orderId`.
- **`PaymentData` helpers** — `isSuccessful`, `amountInMajorUnit`, `feesInMajorUnit`.
- **`toString()`, `copyWith()`, `==`, `hashCode`** added to `Authorization`, `Customer`, `PaymentData`.
- **`PaystackException`** — typed exception class with `message`, `statusCode`, `responseBody`.
- **Re-exports** — importing `pay_with_paystack.dart` now also exports all model types.

### 🐛 Bug Fixes
- **Fixed crash** when a network exception was thrown during `_makePaymentRequest`:
  the old code force-unwrapped `response!` after the exception was caught, causing a
  `Null check operator used on a null value` crash. Now throws a typed `PaystackException`.
- `NavigationDecision.prevent` is now returned when the cancel/callback URL is detected,
  preventing the WebView from navigating away before the verification completes.

### 🧪 Tests
- Added a comprehensive unit test suite covering all model classes, the UUID generator,
  `PaystackChannel`, and `PaystackException`.

## 1.0.14

- Previous release.
