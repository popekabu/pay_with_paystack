## 1.2.0

### ✨ New Customer Features
- **Customer prefill** — `customerFirstName`, `customerLastName`, `customerPhone` pre-fill
  the Paystack checkout form and appear on the Dashboard automatically.
- **Cart items** — `cartItems: List<PaystackCartItem>` attaches typed line items to the
  transaction metadata (name, amount, quantity). Amounts are in the major currency unit.
- **Custom fields** — `customFields: List<PaystackCustomField>` provides typed, structured
  fields visible on the Paystack Dashboard for every transaction.
- **Split payments** — new `subaccount`, `splitCode`, `transactionCharge`, and `bearer`
  parameters for routing payments to subaccounts or pre-defined split groups.
- **Subscription invoice limit** — `invoiceLimit` controls how many times a customer is
  charged on a subscription plan.
- **`PaystackBearer` enum** — type-safe `account` / `subaccount` fee-bearer selection.
- **`PaystackCartItem` model** — typed cart line item with `name`, `amount`, `quantity`.
- **`PaystackCustomField` model** — typed custom field with `displayName`, `variableName`, `value`.
- All new model types are automatically exported from `pay_with_paystack.dart`.

---

## 1.1.0

### ✨ New Features
- **`PaystackChannel` enum** — type-safe channel selection.
- **`plan` parameter** — expose subscription plan codes through the public API.
- **`metadata` is now typed** — `Map<String, dynamic>?` instead of `dynamic`.
- **Customisable AppBar** — `showAppBar`, `appBarTitle`, `appBarColor`, `appBarTextColor`.
- **Custom loading widget** — `loadingWidget` parameter.
- **Custom error widget** — `errorWidget` builder with retry callback.
- **Retry button** — the default error screen retries the payment initialisation.
- **Verification overlay** — non-dismissible overlay while verifying the transaction.
- **Branded loading & error UIs** — pulsing Paystack-green logo animation.
- **`Authorization` new fields** — `expMonth`, `expYear`, `reusable`, `signature`.
- **`Customer` new fields** — `metadata`, computed `fullName` getter.
- **`PaymentData` new fields** — `requestedAmount`, `orderId`.
- **`PaymentData` helpers** — `isSuccessful`, `amountInMajorUnit`, `feesInMajorUnit`.
- **`toString()`, `copyWith()`, `==`, `hashCode`** on all models.
- **`PaystackException`** — typed exception with `message`, `statusCode`, `responseBody`.
- **Re-exports** — importing `pay_with_paystack.dart` now exports all model types.

### 🐛 Bug Fixes
- Fixed crash: `response!` force-unwrap after a caught exception now throws a typed
  `PaystackException` instead of crashing with `Null check operator used on a null value`.
- `NavigationDecision.prevent` returned when the cancel/callback URL is detected.

### 🧪 Tests
- Comprehensive unit test suite for all models and utilities.

---

## 1.0.14

- Previous release.
