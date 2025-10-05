package io.wliamp.pay.entity;

import io.wliamp.pay.constant.TransactionStatus;
import lombok.Builder;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.math.BigDecimal;

@Data
@Builder
@Table("payments")
public class Payment {
    @Id
    private Long id;

    private String userId;
    private BigDecimal amount;
    private String currency;
    private TransactionStatus status;
}
