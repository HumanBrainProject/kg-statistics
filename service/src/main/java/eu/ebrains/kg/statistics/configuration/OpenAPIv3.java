package eu.ebrains.kg.statistics.configuration;


import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenAPIv3 {

    @Bean
    public OpenAPI customOpenAPI() {
        OpenAPI openapi = new OpenAPI().openapi("3.0.3");
        String description = "This is the API of the EBRAINS Knowledge Graph Statistics";

        return openapi.info(new Info().version("v3.0.0").title("This is the EBRAINS KG Statistics API")
                .description(description)
                .license(new License().name("Apache 2.0").url("https://www.apache.org/licenses/LICENSE-2.0.html"))
                .termsOfService("https://kg.ebrains.eu/search-terms-of-use.html"));
    }
}