# Merchant

## Authorize

### Dev

#### API Endpoint
`POST /hamsaqua/payment/authorize`
- Request: {`merchantId`, `payerId`, `cardInfo`, `amount`, `currency`, `orderId`}
- Response: {`transactionId`, `status`, `message`, `correlationId`}

#### Processing Flow
- Validate request payload
- Generate or propagate X-Correlation-ID
- Call GatewayService /authorization (synchronous REST call)
- Receive and normalize AuthorizationResponseDTO
- Return the result to the frontend
- Log each step with JSON logs (correlationId, txnId, status)

#### Integration Rules
- Call Gateway via REST
    - Headers: `Authorization`, `X-Correlation-ID`
    - Timeout: **3s**, retry **2x** with exponential backoff (500ms → 1s)
- On timeout or error, return appropriate HTTP status

#### Error Handling
| Condition        | Response                         | HTTP |
| ---------------- | -------------------------------- | ---- |
| Invalid input    | {error: "Invalid request"}       | 400  |
| Unauthorized     | {error: "Unauthorized"}          | 401  |
| Gateway timeout  | {error: "Gateway unavailable"}   | 504  |
| Internal failure | {error: "Internal server error"} | 500  |

### Test
- Valid payment → returns APPROVED or DECLINED
- Missing or invalid field → 400
- Invalid token → 401
- Gateway timeout → 504
---
