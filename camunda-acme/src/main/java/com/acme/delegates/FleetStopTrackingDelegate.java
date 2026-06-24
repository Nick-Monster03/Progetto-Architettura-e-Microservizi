package com.acme.delegates;

import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.HashMap;
import java.util.Map;

@Component("fleetStopTrackingDelegate")
public class FleetStopTrackingDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(FleetStopTrackingDelegate.class);
    private static final String FLEET_URL = "http://fleet-gateway:8082/stopTracking";

    @Override
    public void execute(DelegateExecution execution) throws Exception {

        String userId = (String) execution.getVariable("userId");
        String vehicleId = (String) execution.getVariable("vehicleId");

        log.info("=== [FLEET STOP] User: {} | Vehicle: {} ===", userId, vehicleId);

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
            log.error("FleetGateway irraggiungibile durante stopTracking", e);
            throw e;
        }

        ObjectMapper mapper = new ObjectMapper();
        JsonNode json = mapper.readTree(response.getBody());
        boolean success = json.path("success").asBoolean(false);

        if (!success) {
            String message = json.path("message").asText("Fleet ha rifiutato stopTracking senza un messaggio");
            log.error("stopTracking fallito per vehicle {}: {}", vehicleId, message);
            throw new IllegalStateException("stopTracking fallito: " + message);
        }

        Double kilometers = json.path("kilometers").asDouble(0.0);
        Integer finalBattery = json.path("finalBattery").asInt(0);

        Long startTime = (Long) execution.getVariable("rentalStartTime");
        if (startTime == null) {
            log.warn("rentalStartTime assente per vehicle {}: durata calcolata come 0", vehicleId);
        }
        int durationMinutes = (startTime != null) ? (int) ((System.currentTimeMillis() - startTime) / 60000) : 0;

        execution.setVariable("kilometers", kilometers);
        execution.setVariable("finalBattery", finalBattery);
        execution.setVariable("duration", durationMinutes);

        log.info("Tracking stopped - Km: {} | Battery: {}% | Duration: {}min", kilometers, finalBattery, durationMinutes);
    }
}