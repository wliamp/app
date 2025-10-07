# Authorize
* Implement Kafka consumer for `payment.authorize.request.v1`.
* Validate and enrich transaction data.
* Persist to local `processor_transactions` table.
* Perform synchronous HTTP call to Network (`/v1/network/route`).
* Parse issuer/network response and update transaction record.
* Publish `payment.authorize.result.v1` and `audit.log.v1`.
* Apply idempotency using `transactionId` as key.
* Handle retries for network call with exponential backoff.
* Add DLQ support for failed events.
* Add OpenTelemetry spans and metrics for issuer latency and retries.
