package eu.ebrains.kg.statistics;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;


@Configuration
@EnableAutoConfiguration
@ComponentScan
public class ServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(ServiceApplication.class, args);
	}


	@Bean
	@SuppressWarnings("java:S4502") //We suppress the csrf disable warning because we have a stateless, token-base API (also see https://www.baeldung.com/spring-security-csrf#stateless-spring-api ).
	public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
		/**
		 *  The http security is quite simple here because we're just fast-forwarding the token
		 *  ( {@link eu.ebrains.kg.service.configuration.OauthClient ) to KG core and
		 *  let this one manage the access permissions....
		 */
		http.csrf(AbstractHttpConfigurer::disable);
		http.authorizeHttpRequests(a -> a.anyRequest().permitAll());
		return http.build();
	}
}
