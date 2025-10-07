# Authorize
* Implement API integration to call `POST /v1/authorize` at Gateway.
* Manage merchant-side order table: store `orderId`, `transactionId`, `status`, `amount`, and `timestamps`.
* Handle immediate ACK response (**ACCEPTED** or **REJECTED**).
* Implement webhook/callback endpoint to receive final result from Gateway.
* Update order status upon callback: **APPROVED**, **DECLINED**, **ERROR**.
* Add retry/backoff for webhook delivery if Merchant callback fails.
* Log all interactions with `correlationId` for traceability.
* Add metrics: request count, success rate, callback latency.

---
