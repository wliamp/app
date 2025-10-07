# Authorize
* Implement Kafka consumer for `payment.authorize.request.v1`.
* Compute risk score using rule engine or ML stub.
* Publish `fraud.check.result.v1` with score and action.
* Optionally publish `audit.log.v1` for blocked/reviewed cases.
* Use cache for idempotent responses by `transactionId`.
* Add DLQ handling and retry policies.
* Add observability for processing latency and hit rate.
