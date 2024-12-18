# 1.0.11

- Fixes:
  - Transaction Not Completed Callback Issue:
Addressed an issue where the transactionNotCompleted function was not being triggered due to a Paystack-related limitation. The "Close" button URL is not explicitly defined in their documentation.
  - The transactionNotCompleted function now properly returns a status string to the developer, allowing this status to be displayed to the app user for better clarity
