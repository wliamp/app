package io.wliamp.pay.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;

import java.math.BigDecimal;

@Builder
public record PaymentRequest(@NotBlank String userId,
                             @NotNull BigDecimal amount,
                             @NotBlank String currency) {
}
