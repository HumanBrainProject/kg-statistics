package eu.ebrains.kg.statistics.services;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class TypesClient {
    private final ServiceCall kg;

    public TypesClient(ServiceCall kg) {
        this.kg = kg;
    }

    @SuppressWarnings("java:S3740") // Generics are kept intentionally
    public Map getTypes(String stage) {
        String relativeUrl = String.format("types?stage=%s&withProperties=true&withCounts=true", stage);
        return kg.client().get()
                .uri(kg.url(relativeUrl))
                .headers(h -> h.add(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE))
                .retrieve()
                .bodyToMono(Map.class)
                .block();
    }
}

