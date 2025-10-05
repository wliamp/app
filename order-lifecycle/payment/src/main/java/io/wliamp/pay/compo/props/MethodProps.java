package io.wliamp.pay.compo.props;

import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Setter
@Getter
@Component
@ConfigurationProperties(prefix = "payment.method")
public class MethodProps {
    private Gateway creditCard;

    @Data
    public static class Gateway {
        private String baseUrl;
        private String apiKey;
    }
}
