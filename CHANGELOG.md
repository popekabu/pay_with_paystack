## 1.3.0

### New Features

- Added `timeout` parameter (`Duration`, default 30 s) to `now()` to prevent indefinite
  hanging on slow networks.
- Added `onTimeout` callback, fired specifically when the API call times out. Falls back to
  `transactionNotCompleted('timeout')` if not set.
- Added `enableLogging` flag. Set `true` (or use `PaystackConfig(enableLogging: kDebugMode)`)
  to print request/response details via `debugPrint`. Silent in release builds.
- Added WebView progress bar — a `LinearProgressIndicator` now appears at the top of the
  AppBar while the checkout page loads.
- Added `PaymentData.requestedAmountInMajorUnit` convenience getter, mirroring
  `amountInMajorUnit` for the `requestedAmount` field.
- Added `PaystackConfig` — app-level config class. Call `PayWithPayStack.configure(config)`
  once in `main()` to set `secretKey`, `currency`, `callbackUrl`, `enableLogging`, and
  `timeout` as global defaults. Individual `now()` calls can still override any field.
- Added `PayWithPayStack.configure()`, `clearConfig()`, and `currentConfig` — static API for
  managing global config.
- Added `transactionCancelled` callback — a `VoidCallback?` fired when the user explicitly
  closes the WebView without completing a payment (close button or cancel URL). Previously
  both cancel and failure routed to `transactionNotCompleted`.
- `secretKey`, `currency`, and `callbackUrl` are now optional on `now()` when a global
  `PaystackConfig` has been set via `configure()`.
- Added `PaystackCartItem.imageUrl` — optional product image URL included in cart metadata,
  visible on the Paystack Dashboard when viewing a transaction.
- Added `PaystackCurrency` enum — typed, IDE-friendly enum for all supported Paystack
  currencies: `ngn`, `ghs`, `zar`, `usd`, `kes`, `xof`, `egp`, `rwf`. Use
  `PaystackCurrency.ghs.value` instead of the raw string `'GHS'`.
- Added `chargeAuthorization()` — silently charges a returning customer using a saved
  authorization code without showing a WebView. Calls
  `POST /transaction/charge_authorization` directly.
- Added `PaystackBulkChargeItem` — typed model for building bulk charge batches. Use
  `toJson()` to serialise items for `POST /bulkcharge`.

### Improvements

- `_checkTransactionStatus` now handles `TimeoutException` explicitly with a user-friendly
  message instead of a silent network error.
- The AppBar close button now correctly fires `transactionCancelled` instead of
  `_checkTransactionStatus` on a user-initiated close.

### Exports

- `PaystackConfig`, `PaystackCurrency`, and `PaystackBulkChargeItem` are now exported from
  `pay_with_paystack.dart`.

## 1.2.0

### New Features

- Added customer prefill — `customerFirstName`, `customerLastName`, and `customerPhone`
  pre-fill the Paystack checkout form and appear on the Dashboard automatically.
- Added `cartItems: List<PaystackCartItem>` — attaches typed line items to transaction
  metadata (name, amount, quantity). Amounts are in the major currency unit.
- Added `customFields: List<PaystackCustomField>` — typed, structured fields visible on the
  Paystack Dashboard for every transaction.
- Added split payment parameters — `subaccount`, `splitCode`, `transactionCharge`, and
  `bearer` for routing payments to subaccounts or pre-defined split groups.
- Added `invoiceLimit` — controls how many times a customer is charged on a subscription plan.
- Added `PaystackBearer` enum — type-safe `account` / `subaccount` fee-bearer selection.
- Added `PaystackCartItem` model — typed cart line item with `name`, `amount`, `quantity`.
- Added `PaystackCustomField` model — typed custom field with `displayName`, `variableName`,
  `value`.
- All new model types are exported from `pay_with_paystack.dart`.

## 1.1.0

### New Features

- Added `PaystackChannel` enum for type-safe payment channel selection.
- Added `plan` parameter to expose subscription plan codes through the public API.
- `metadata` is now typed as `Map<String, dynamic>?` instead of `dynamic`.
- Added AppBar customisation — `showAppBar`, `appBarTitle`, `appBarColor`, `appBarTextColor`.
- Added `loadingWidget` parameter for a custom loading widget.
- Added `errorWidget` builder parameter for a custom error widget with retry callback.
- Retry button on the default error screen retries payment initialisation.
- Added a non-dismissible verification overlay shown while verifying the transaction.
- Added branded loading and error UIs with a pulsing logo animation.
- Added `expMonth`, `expYear`, `reusable`, and `signature` fields to `Authorization`.
- Added `metadata` field and computed `fullName` getter to `Customer`.
- Added `requestedAmount` and `orderId` fields to `PaymentData`.
- Added `isSuccessful`, `amountInMajorUnit`, and `feesInMajorUnit` helpers to `PaymentData`.
- Added `toString()`, `copyWith()`, `==`, and `hashCode` to all models.
- Added `PaystackException` — typed exception with `message`, `statusCode`, `responseBody`.
- Importing `pay_with_paystack.dart` now re-exports all model types.

### Bug Fixes

- Fixed crash: `response!` force-unwrap after a caught exception now throws a typed
  `PaystackException` instead of crashing with `Null check operator used on a null value`.
- `NavigationDecision.prevent` is now returned when the cancel or callback URL is detected.

### Tests

- Added comprehensive unit test suite for all models and utilities.

## 1.0.14

- Initial tracked release.
