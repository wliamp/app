package io.wliamp.pay.compo.helper;

import io.wliamp.pay.entity.Payment;
import reactor.core.publisher.Mono;

public interface MethodHelper {
    Mono<Boolean> execute(Payment payment);
}
