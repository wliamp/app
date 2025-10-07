# Authorize
* Implement `POST /v1/network/route`.
* Map inbound request to issuer endpoint based on routing table.
* Implement client for Issuer call `POST /v1/issuer/authorize`.
* Add circuit breaker and timeout configuration.
* Parse and return Issuer response to Processor.
* Maintain small config DB for routing rules.
* Add structured logging and correlation propagation.
* Expose health and metrics endpoints (`network.route.latency`).
