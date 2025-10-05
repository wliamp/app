package io.wliamp.msg.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import io.wliamp.msg.dto.ChatMessage;

@Configuration
public class RedisConfig {
    @Bean
    public ReactiveRedisTemplate<String, ChatMessage> reactiveRedisTemplate(
            ReactiveRedisConnectionFactory connectionFactory, ObjectMapper mapper) {
        Jackson2JsonRedisSerializer<ChatMessage> serializer = new Jackson2JsonRedisSerializer<>(mapper, ChatMessage.class);
        RedisSerializationContext<String, ChatMessage> serializationContext =
                RedisSerializationContext.<String, ChatMessage>newSerializationContext(new StringRedisSerializer())
                        .value(serializer)
                        .hashKey(new StringRedisSerializer())
                        .hashValue(serializer)
                        .build();
        return new ReactiveRedisTemplate<>(connectionFactory, serializationContext);
    }
}
