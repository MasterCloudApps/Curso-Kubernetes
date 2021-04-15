package es.codeurjc.k8sdevtools.demoservice;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RestHelloWorld {
	
	@GetMapping("/")
	public String sayHello() {
		return "Hello world REST8";
	}

}
