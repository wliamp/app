# Authorize
* Unit test: request validation, idempotency key logic.
* Unit test: database persistence and status transitions.
* Unit test: event payload mapping for both request and audit topics.
* Integration test: full round-trip with Processor mock.
* Failure test: Kafka publish error → outbox recovery.
* Negative test: duplicate requests, invalid schema, missing auth.
* Performance test: **SLA < 2s** for synchronous ACK.

---
