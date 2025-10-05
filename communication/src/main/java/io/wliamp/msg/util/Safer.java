package io.wliamp.msg.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import io.wliamp.msg.dto.ChatMessage;

@Slf4j
public class Safer {
    public static String safeJson(ObjectMapper mapper, ChatMessage msg) {
        try {
            return mapper.writeValueAsString(msg);
        } catch (JsonProcessingException e) {
            log.error("JSON serialization failed", e);
            return "{\"sender\":\"" + safe(msg.sender()) + "\",\"content\":\"" + safe(msg.content()) + "\"}";
        }
    }

    private static String safe(String s) {
        return s == null ? "" : s.replace("\"", "\\\"");
    }
}
