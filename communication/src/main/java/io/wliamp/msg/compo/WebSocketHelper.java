package io.wliamp.msg.compo;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.socket.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;
import io.wliamp.msg.dto.ChatMessage;
import io.wliamp.msg.service.CacheService;
import io.wliamp.msg.service.PersistenceService;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static io.wliamp.msg.util.Extractor.extractChannel;
import static io.wliamp.msg.util.Safer.safeJson;

@Component
@Slf4j
@RequiredArgsConstructor
public class WebSocketHelper implements WebSocketHandler {

    private final ObjectMapper mapper;
    private final CacheService cacheService;
    private final PersistenceService persistenceService;

    @Value("${chat.history-limit}")
    private int historyLimit;

    @Value("${chat.max-message-length}")
    private int maxMessageLength;

    private final Map<String, Sinks.Many<ChatMessage>> channelSinks = new ConcurrentHashMap<>();

    private Sinks.Many<ChatMessage> getSink(String channel) {
        return channelSinks.computeIfAbsent(channel, k -> Sinks.many().multicast().directBestEffort());
    }

    @Override
    @NonNull
    public Mono<Void> handle(WebSocketSession session) {
        String channel = extractChannel(session.getHandshakeInfo().getUri()).orElse("global");
        log.debug("WebSocket session {} connected on channel '{}'", session.getId(), channel);
        Flux<WebSocketMessage> history = cacheService
                .load(channel)
                .map(msgSend -> safeJson(mapper, msgSend))
                .map(session::textMessage)
                .onErrorResume(e -> {
                    log.error("Error reading history for channel {}", channel, e);
                    return Flux.empty();
                });
        Flux<WebSocketMessage> broadcast = getSink(channel).asFlux()
                .map(msgSend -> safeJson(mapper, msgSend))
                .map(session::textMessage)
                .onErrorResume(e -> {
                    log.error("Broadcast error on channel {}", channel, e);
                    return Flux.empty();
                });
        Flux<WebSocketMessage> outgoing = Flux.concat(history, broadcast);
        Mono<Void> inbound = session.receive()
                .map(WebSocketMessage::getPayloadAsText)
                .flatMap(payload -> {
                    ChatMessage msg;
                    try {
                        msg = mapper.readValue(payload, ChatMessage.class);
                    } catch (JsonProcessingException e) {
                        log.warn("Invalid payload from session {}: {}", session.getId(), payload);
                        return Mono.empty();
                    }
                    if (msg.channel() == null || msg.channel().isBlank()) {
                        msg = msg.withChannel(channel);
                    }
                    if (msg.content() == null || msg.content().isBlank()) {
                        return Mono.empty();
                    }
                    if (msg.content().length() > maxMessageLength) {
                        log.warn("Message too long from {}: length={}", msg.sender(), msg.content().length());
                        return Mono.empty();
                    }
                    if (msg.timestamp() == 0) {
                        msg = msg.withTimestamp(System.currentTimeMillis());
                    }
                    getSink(msg.channel()).tryEmitNext(msg);
                    return cacheService.cache(msg.channel(), msg, historyLimit)
                            .then(persistenceService.persist(msg))
                            .then();
                })
                .doOnError(e -> log.error("Error in inbound stream", e))
                .then();
        return session.send(outgoing)
                .and(inbound)
                .doOnSubscribe(s -> log.debug("WS session opened: {}", session.getId()))
                .doFinally(sig -> log.debug("WS session closed: {} ({})", session.getId(), sig));
    }
}
