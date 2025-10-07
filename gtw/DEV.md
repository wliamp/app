# Authorize
### Implement `POST /v1/authorize`
- Validate signature + idempotency headers
- Publish Kafka `auth.request.v1`
- Persist request state if needed (Redis/in-memory)
### Kafka consumer:
- Subscribe `auth.result.v1`
- Update request state and POST result to Merchant webhook
### `MerchantCallbackClient`:
- Async retry/backoff
- Correlate via correlationId
### Add OpenTelemetry trace propagation 
Merchant → Gateway → Processor

---

