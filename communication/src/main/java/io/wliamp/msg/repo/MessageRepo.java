package io.wliamp.msg.repo;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import io.wliamp.msg.entity.Message;

public interface MessageRepo extends ReactiveMongoRepository<Message, String> {
    Flux<Message> findByChannelOrderByTimestampDesc(String channel);
}
