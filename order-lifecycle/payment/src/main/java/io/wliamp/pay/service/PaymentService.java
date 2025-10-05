package io.wliamp.pay.service;

import io.wliamp.pay.compo.helper.MethodHelper;
import io.wliamp.pay.constant.TransactionStatus;
import io.wliamp.pay.dto.PaymentRequest;
import io.wliamp.pay.dto.PaymentResponse;
import io.wliamp.pay.entity.Payment;
import io.wliamp.pay.repo.PaymentRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class PaymentService {
    private final PaymentRepo paymentRepo;

    private final Map<String, MethodHelper> methodHelpers;

    public Mono<PaymentResponse> process(String method, PaymentRequest paymentRequest) {
        MethodHelper helper = methodHelpers.get(method);
        return (helper == null ? Mono.<Payment>error(
                new IllegalArgumentException("Unsupported payment method: " + method.toUpperCase())) : Mono.just(
                Payment.builder()
                        .userId(paymentRequest.userId())
                        .amount(paymentRequest.amount())
                        .currency(paymentRequest.currency())
                        .status(TransactionStatus.PENDING)
                        .build()))
                .flatMap(paymentRepo::save)
                .flatMap(saved -> {
                    assert helper != null;
                    return helper.execute(saved).flatMap(success -> {
                        saved.setStatus(success ? TransactionStatus.SUCCESS : TransactionStatus.FAILED);
                        return paymentRepo.save(saved);
                    });
                }).map(updated -> new PaymentResponse(
                        updated.getId().toString(),
                        updated.getStatus(),
                        updated.getStatus() == TransactionStatus.SUCCESS ? "Payment successful" : "Payment failed"));
    }
}

