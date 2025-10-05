package io.wliamp.msg.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import io.wliamp.msg.entity.Message;
import io.wliamp.msg.repo.MessageRepo;

@Service
@RequiredArgsConstructor
public class MessageService {
    private final MessageRepo messageRepo;

    public Mono<Message> save(Message message) {
        return messageRepo.save(message);
    }

    public Flux<Message> getRecentMessages(String channel, int limit) {
        return messageRepo.findByChannelOrderByTimestampDesc(channel).take(limit);
    }
}
