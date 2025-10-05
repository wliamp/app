package io.wliamp.msg.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.ReactiveListOperations;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import io.wliamp.msg.dto.ChatMessage;

@Service
@RequiredArgsConstructor
public class CacheService {
    private final ReactiveRedisTemplate<String, ChatMessage> redisTemplate;

    public Mono<Long> cache(String channel, ChatMessage msg, int historyLimit) {
        ReactiveListOperations<String, ChatMessage> ops = redisTemplate.opsForList();
        String key = "chat:" + channel;
        return ops.leftPush(key, msg).flatMap(count -> redisTemplate
                .opsForList()
                .trim(key, 0, historyLimit - 1)
                .thenReturn(count));
    }

    public Flux<ChatMessage> load(String channel) {
        String key = "chat:" + channel;
        return redisTemplate.opsForList().range(key, 0, -1);
    }
}
