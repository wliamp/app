package io.wliamp.pay.compo.handler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;

@Component
@Slf4j
@RequiredArgsConstructor
public class ForwardHandler {
    private final WebClient.Builder webBuilder;

    public <T> Mono<T> post(String baseUrl, String uri, Map<String, String> headers, Object body, Class<T> responseType) {
        return webBuilder.baseUrl(baseUrl)
                .build()
                .post()
                .uri(uri)
                .headers(h -> Optional.ofNullable(headers).ifPresent(hdrs -> hdrs.forEach(h::set)))
                .bodyValue(body)
                .retrieve()
                .onStatus(HttpStatusCode::isError, resp -> resp.bodyToMono(String.class)
                        .flatMap(errorBody -> Mono.error(new RuntimeException("Downstream error: " + errorBody))))
                .bodyToMono(responseType)
                .timeout(Duration.ofSeconds(10))
                .doOnError(error -> log.error("Error during POST to {}{}: {}", baseUrl, uri, error.getMessage()))
                .onErrorResume(error -> {
                    log.warn("Fallback triggered for POST {}{}", baseUrl, uri);
                    return Mono.empty();
                });
    }
}
