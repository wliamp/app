package io.wliamp.msg.dto;

import lombok.With;

@With
public record ChatMessage(String sender, String channel, String content, long timestamp) {}
