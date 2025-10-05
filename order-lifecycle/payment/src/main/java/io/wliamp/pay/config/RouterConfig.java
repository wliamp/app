package io.wliamp.pay.config;

import io.wliamp.pay.compo.handler.RouteHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import static org.springframework.web.reactive.function.server.RequestPredicates.path;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@Configuration
@RequiredArgsConstructor
public class RouterConfig {
    private final RouteHandler routeHandler;

    @Bean
    public RouterFunction<ServerResponse> authRoutes() {
        return route()
                .route(path("/pay"), routeHandler::payment)
                .build();
    }
}
