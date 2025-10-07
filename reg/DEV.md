# Authorize
* Implement Kafka consumers for `audit.log.v1`, `payment.authorize.request.v1`, and `payment.authorize.result.v1`.
* Build append-only audit storage in DB or S3 sink.
* Store full event payloads with `payloadHash` and `metadata`.
* Provide read-only API for audit queries.
* Implement immutability checks and access control.
* Add event ingestion retries and local outbox buffer.
* Add retention and encryption configuration.
* Expose observability metrics (`audit.events.stored`, `audit.write.latency`).
