# Authorize
* Unit test: fraud rule logic and score computation.
* Unit test: event payload mapping for result topic.
* Integration test: consume **AUTH_REQUESTED** → publish **FRAUD_RESULT**.
* DLQ test: invalid message triggers DLQ.
* Idempotency test: same transaction produces same result.
* Fault test: simulate processing exception and recovery.
* Metrics test: verify `fraud.alert.count` increments properly.
