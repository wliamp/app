# Authorize
* Implement `POST /v1/issuer/authorize` endpoint.
* Load account dataset (payer → balance, status).
* Apply simple business rules (`balance` ≥ `amount`, card active).
* Generate `authCode` when approved.
* Return structured response with status **APPROVED**, **DECLINED**, or **ERROR**.
* Maintain account table updates and mock issuer data.
* Add logging and metrics (`issuer.auth.calls`, `issuer.approval.rate`).
