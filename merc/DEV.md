# Authorize

### Implement `POST /api/v1/pay`
- Validate input: `orderId`, `amount`, `cardToken`
- Generate `correlationId`, `idempotencyKey`
- Insert record → table `orders`
- Call Gateway `/v1/authorize` (HTTP client)
- Handle ACK → update `status` = **PENDING** or **DECLINED**

### Implement `POST /webhook/payment/result`
- Parse event `payment.authorize.result.v1`
- Update `orders.status` by `transactionId`
- Log and ignore unknown transactions

### Create `GatewayClient`
- Add headers `X-Correlation-Id`, `Idempotency-Key`
- `Timeout` = **3s**, retry once on **5xx**

### DB schema:
- `orders(order_id, txn_id, correlation_id, amount, currency, status, idempotency_key, timestamps)`
- Unique `(merchant_id, idempotency_key)`

### Add observability:
OpenTelemetry traces + JSON logs

---
