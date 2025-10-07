# Authorize
* Unit test: validate serialization/deserialization of Gateway request/response.
* Unit test: verify order persistence and status updates.
* Integration test: full flow with Gateway mock (ACK + callback).
* Integration test: retry behavior when webhook fails.
* Negative test: invalid input, network timeout, duplicate `orderId`.
* Observability test: ensure `correlationId` logged across flows.

---
