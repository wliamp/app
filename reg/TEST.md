# Authorize
* Unit test: payload hashing and schema validation.
* Unit test: append-only write enforcement.
* Integration test: consume multi-topic → store → query validation.
* Negative test: duplicate event ignored, invalid hash rejected.
* Security test: ensure read-only behavior, no update/delete allowed.
* Performance test: high ingest volume and retention rotation.
* Observability test: metrics emitted for event counts and latency.
