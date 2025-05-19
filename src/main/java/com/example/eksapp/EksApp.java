package com.example.eksapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class EksApp {
    public static void main(String[] args) {
        SpringApplication.run(EksApp.class, args);
    }
}

@RestController
class DemoController {

    @GetMapping("/")
    public String home() {
        return "i removed the image tag in the values.yml file and this is the green deployment.";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}