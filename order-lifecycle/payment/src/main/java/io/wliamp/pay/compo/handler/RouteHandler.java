package io.wliamp.pay.compo.handler;

import io.wliamp.pay.dto.PaymentRequest;
import io.wliamp.pay.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

import java.util.Map;

@Component
@RequiredArgsConstructor
public class RouteHandler {
    private final PaymentService service;

    public Mono<ServerResponse> payment(ServerRequest request) {
        String party = request.pathVariable("method");
        return request.bodyToMono(PaymentRequest.class)
                .flatMap(req -> service.process(party, req))
                .flatMap(resp -> ServerResponse.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(resp))
                .onErrorResume(e -> ServerResponse.status(HttpStatus.BAD_REQUEST)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(Map.of("error", e.getMessage())));
    }
}
