package eu.ebrains.kg.statistics.configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.client.AuthorizedClientServiceOAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientService;
import org.springframework.security.oauth2.client.RemoveAuthorizedClientOAuth2AuthorizationFailureHandler;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.reactive.function.client.ServletOAuth2AuthorizedClientExchangeFilterFunction;
import org.springframework.web.reactive.function.client.ClientRequest;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;

import javax.servlet.http.HttpServletRequest;

@Configuration
public class OauthClient {
    private final ExchangeStrategies exchangeStrategies = ExchangeStrategies.builder()
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1000000)).build();

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Bean
    WebClient webClient(ClientRegistrationRepository clientRegistrations, OAuth2AuthorizedClientService authorizedClientService, HttpServletRequest request) {
        AuthorizedClientServiceOAuth2AuthorizedClientManager clientManager = new AuthorizedClientServiceOAuth2AuthorizedClientManager(clientRegistrations, authorizedClientService);
        ServletOAuth2AuthorizedClientExchangeFilterFunction oauth2 = new ServletOAuth2AuthorizedClientExchangeFilterFunction(clientManager);
        oauth2.setAuthorizationFailureHandler(new RemoveAuthorizedClientOAuth2AuthorizationFailureHandler(
                (clientRegistrationId, principal, attributes) -> {
                    logger.info("Resource server authorization failure for clientRegistrationId={}", clientRegistrationId);
                    authorizedClientService.removeAuthorizedClient(clientRegistrationId, principal.getName());
                })
        );
        oauth2.setDefaultClientRegistrationId("kg");
        return WebClient.builder().exchangeStrategies(exchangeStrategies).apply(oauth2.oauth2Configuration()).filter((clientRequest, nextFilter) -> {
            ClientRequest updatedHeaders = ClientRequest.from(clientRequest).headers(h -> {
                h.put("Client-Authorization", h.get("Authorization"));
            }).build();
            return nextFilter.exchange(updatedHeaders);
        }).build();
    }
}
