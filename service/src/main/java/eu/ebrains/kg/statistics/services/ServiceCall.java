package eu.ebrains.kg.statistics.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

@Component
public class ServiceCall {
    private final WebClient webClient;
    private final String kgCoreEndpoint;

    public ServiceCall(WebClient webClient, @Value("${kgcore.endpoint}") String kgCoreEndpoint) {
        this.webClient = webClient;
        this.kgCoreEndpoint = kgCoreEndpoint;
    }

    public String url(String relativeUri){
        return String.format("%s/%s", kgCoreEndpoint, relativeUri);
    }

    public WebClient client() {
        return webClient;
    }
}
