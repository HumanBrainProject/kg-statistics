package eu.ebrains.kg.statistics.api;

import eu.ebrains.kg.statistics.services.TypesClient;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RequestMapping("/types")
@RestController
public class Types {

    public  final TypesClient typesClient;

    public Types(TypesClient typesClient) {
        this.typesClient = typesClient;
    }

    @SuppressWarnings("java:S3740") // Generics are kept intentionally
    @GetMapping
    public Map getTypes(@RequestParam("stage") String stage) {
        return typesClient.getTypes(stage);
    }
}
