package io.wliamp.pay.repo;

import io.wliamp.pay.entity.Payment;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;

public interface PaymentRepo extends ReactiveCrudRepository<Payment, Long> {
}
