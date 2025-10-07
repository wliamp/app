# Authorize
* Unit test: event deserialization and validation logic.
* Unit test: network response mapping and DB update flow.
* Unit test: retry logic for network timeouts.
* Integration test: consume event → call network mock → publish result.
* DLQ test: verify failed messages route to DLQ.
* Idempotency test: reprocessing same event should not duplicate results.
* Load test: concurrent event consumption and processing.
