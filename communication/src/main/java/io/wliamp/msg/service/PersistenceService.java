package io.wliamp.msg.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import io.wliamp.msg.dto.ChatMessage;
import io.wliamp.msg.entity.Message;
import io.wliamp.msg.repo.MessageRepo;

@Service
@RequiredArgsConstructor
public class PersistenceService {
    private final MessageRepo messageRepo;

    public Mono<Message> persist(ChatMessage msg) {
        Message e = new Message();
        e.setSender(msg.sender());
        e.setContent(msg.content());
        e.setChannel(msg.channel());
        e.setTimestamp(msg.timestamp());
        return messageRepo.save(e);
    }
}
