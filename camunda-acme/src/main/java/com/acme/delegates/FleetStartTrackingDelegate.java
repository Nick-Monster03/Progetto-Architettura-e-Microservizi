package com.acme.delegates;

import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("fleetStartTrackingDelegate")
public class FleetStartTrackingDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(FleetStartTrackingDelegate.class);
    private static final String FLEET_URL = "http://fleet-gateway:8082/startTracking";

    @Override
    public void execute(DelegateExecution execution) throws Exception {

        String userId = (String) execution.getVariable("userId");
        String vehicleId = (String) execution.getVariable("vehicleId");

        log.info("=== [FLEET START] User: {} | Vehicle: {} ===", userId, vehicleId);

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("userId", userId);
        requestBody.put("vehicleId", vehicleId);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, String>> request = new HttpEntity<>(requestBody, headers);

        ResponseEntity<String> response;
        try {
            response = restTemplate.postForEntity(FLEET_URL, request, String.class);
        } catch (Exception e) {
            log.error("FleetGateway irraggiungibile durante startTracking", e);
            throw e;
        }

        ObjectMapper mapper = new ObjectMapper();
        JsonNode json = mapper.readTree(response.getBody());
        boolean success = json.path("success").asBoolean(false);

        if (!success) {
            String message = json.path("message").asText("Fleet ha rifiutato startTracking senza un messaggio");
            log.error("startTracking fallito per vehicle {}: {}", vehicleId, message);
            throw new IllegalStateException("startTracking fallito: " + message);
        }

        execution.setVariable("rentalStartTime", System.currentTimeMillis());
        log.info("Tracking started");
    }
}