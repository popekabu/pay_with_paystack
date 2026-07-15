/// Platform-conditional export.
///
/// On Flutter Web (`dart.library.html` is available), the checkout screen uses
/// [PaystackWebCheckout], which opens the Paystack URL in a new browser tab
/// via `url_launcher`.
///
/// On all other platforms (Android, iOS, macOS, Windows, Linux), the checkout
/// screen uses [PaystackPayNow], which embeds the Paystack URL in a native
/// WebView via `webview_flutter`.
export 'paystack_pay_now.dart'
    if (dart.library.html) 'paystack_web_checkout.dart';
