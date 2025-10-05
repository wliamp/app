package io.wliamp.pay.compo.helper;

import io.wliamp.pay.compo.handler.ForwardHandler;
import io.wliamp.pay.compo.props.MethodProps;
import io.wliamp.pay.entity.Payment;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.util.Map;

@Component("credit")
@Slf4j
@RequiredArgsConstructor
public class CreditCardHelper implements MethodHelper{
    private final ForwardHandler forwardHandler;

    private final MethodProps methodProps;

    @Override
    public Mono<Boolean> execute(Payment payment) {
        return forwardHandler.post(
                        methodProps.getCreditCard().getBaseUrl(),
                        "/charge",
                        Map.of(
                                "Authorization", "Bearer " + methodProps.getCreditCard().getApiKey(),
                                "X-Trace-Id", MDC.get("traceId")
                        ),
                        Map.of(
                                "amount", payment.getAmount(),
                                "currency", payment.getCurrency(),
                                "userId", payment.getUserId(),
                                "paymentId", payment.getId()
                        ),
                        Map.class
                )
                .map(resp -> Boolean.TRUE.equals(resp != null ? resp.get("success") : null))
                .doOnNext(success -> log.info("[TRACE {}] Credit Card payment {} for {}",
                        MDC.get("traceId"),
                        success ? "SUCCESS" : "FAILED",
                        payment.getId()))
                .doOnError(error -> log.error("[TRACE {}] Credit Card gateway error for {}: {}",
                        MDC.get("traceId"), payment.getId(), error.getMessage()))
                .onErrorResume(error -> Mono.just(false));
    }
}
