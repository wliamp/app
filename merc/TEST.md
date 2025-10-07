# Authorize
- Verify `/api/v1/pay` returns correct ACK on valid input
- Validate DB record created with correct status
- Simulate Gateway responses: **ACCEPTED** / **REJECTED** / **5xx**
- Test idempotent requests (same `orderId` → same `txnId`)
- Validate webhook updates status correctly
- Webhook with invalid `txn` → logged but ignored
- Integration: `/pay` → ACK → webhook → final **APPROVED**
- Performance: **100 req/s**, avg ACK **<1s**, webhook latency **<200ms**

---
