# Authorize
* Implement `POST /v1/authorize` endpoint for external merchants.
* Validate merchant credentials and payload structure.
* Generate `transactionId` and `correlationId`.
* Persist initial record in transactions table with **INITIATED** status.
* Publish `payment.authorize.request.v1` and audit.log.v1.
* Consume `payment.authorize.result.v1` to update transaction status.
* Implement idempotency via `orderId` or `Idempotency-Key`.
* Implement outbox pattern for reliable Kafka publishing.
* Expose callback dispatcher to notify merchants.
* Add tracing, structured logs, and metrics (`gateway.requests`, `publish.failures`).

---

