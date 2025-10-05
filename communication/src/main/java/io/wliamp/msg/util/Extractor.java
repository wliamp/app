package io.wliamp.msg.util;

import java.net.URI;

public class Extractor {
    public static java.util.Optional<String> extractChannel(URI uri) {
        if (uri == null || uri.getQuery() == null) return java.util.Optional.empty();
        return java.util.Arrays.stream(uri.getQuery().split("&"))
                .filter(param -> param.startsWith("channel="))
                .map(param -> param.substring("channel=".length()))
                .findFirst();
    }
}
