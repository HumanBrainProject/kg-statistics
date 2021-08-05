package eu.ebrains.kg.statistics.configuration;


import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Collections;

@Configuration
public class OpenAPIv3 {

    @Bean
    public OpenAPI customOpenAPI(@Value("${eu.ebrains.kg.login.endpoint}") String loginEndpoint) {
        OAuthFlow oAuthFlow = new OAuthFlow();
        oAuthFlow.authorizationUrl(loginEndpoint);
        SecurityScheme userToken = new SecurityScheme().name("Authorization").type(SecurityScheme.Type.OAUTH2).flows(new OAuthFlows().implicit(oAuthFlow)).description("The user authentication");
        SecurityRequirement userWithoutClientReq = new SecurityRequirement().addList("Authorization");

        OpenAPI openapi = new OpenAPI().openapi("3.0.3");
        String description = "This is the API of the EBRAINS Knowledge Graph Statistics";

        return openapi.info(new Info().version("v3.0.0").title("This is the EBRAINS KG Statistics API").description(description).license(new License().name("Apache 2.0").url("https://www.apache.org/licenses/LICENSE-2.0.html")).termsOfService("https://kg.ebrains.eu/search-terms-of-use.html"))
                .components(new Components()).schemaRequirement("Authorization", userToken)
                .security(Collections.singletonList(userWithoutClientReq));
    }
}