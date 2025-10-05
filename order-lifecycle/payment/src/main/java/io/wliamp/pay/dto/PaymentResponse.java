package io.wliamp.pay.dto;

import io.wliamp.pay.constant.TransactionStatus;
import lombok.Builder;

@Builder
public record PaymentResponse(String transactionId, TransactionStatus status, String message) {
}
