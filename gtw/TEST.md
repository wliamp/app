# Authorize
- Validate signature logic (valid, invalid, missing header)
- Test Kafka publish success/failure cases
- Verify duplicate request returns cached response
- Ensure callback sent exactly once per txn
- Integration: Merchant → Gateway → Kafka round-trip
- Load test: callback latency **<500ms**, deduplication works
