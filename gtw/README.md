# Gateway

## Authorize

### Dev

#### API Endpoint
`POST /authorize`
- Request: `AuthorizeRequestDTO`
    {`merchantId`, `payerId`, `cardInfo`, `amount`, `currency`, `orderId`, `correlationId`}
- Response: `AuthorizeResponseDTO`
    {`transactionId`, `authCode`, `status`, `message`}

#### Processing Flow
- Receive and validate incoming authorization requests
- Authenticate merchant (OAuth2 / JWT)
- Generate X-Correlation-ID if not provided
- Persist initial transaction record (INITIATED)
- Forward request to Processor Service (sync call)
- Receive normalized response and update transaction status
- Return response to Merchant Service
- Log every step with correlation ID and transaction ID

#### Integration Rules
- Forward to: `Processor /authorization`
    - Headers: `X-Correlation-ID`, `Authorization`
    - Timeout: **3s**, retry **2x** (backoff 500ms → 1s)
- Circuit breaker: open after 5 consecutive failures, auto-reset after 30s

On failure → return HTTP 504 (timeout) or 500 (internal)

#### Error Handling
| Condition             | Response                         | HTTP |
| --------------------- | -------------------------------- | ---- |
| Invalid schema        | {error: "Invalid request"}       | 400  |
| Unauthorized merchant | {error: "Unauthorized"}          | 401  |
| Processor timeout     | {error: "Processor unavailable"} | 504  |
| Internal failure      | {error: "Internal server error"} | 500  |

#### Logging
- Structured JSON logs
- Fields: timestamp, service, correlationId, transactionId, status, latency

#### 

### Test
- Valid authorization flow → Approved / Declined response returned
- Missing field / invalid schema → 400
- Invalid merchant token → 401
- Processor timeout → 504
- Internal error → 500
- Correlation ID propagation → Verify same ID logged across Gateway & Processor
- Retry logic → Processor unavailable on first call → success on second
- Circuit breaker → Fails open after 5 errors, auto-resets after cooldown
- Structured logging test → All logs include correlationId & txnId
---
