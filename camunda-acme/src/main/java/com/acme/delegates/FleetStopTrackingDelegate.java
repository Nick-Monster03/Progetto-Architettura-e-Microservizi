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
    private static final String FLEET_URL = "http://127.0.0.1:8082/stopTracking";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String userId = (String) execution.getVariable("userId");
        String vehicleId = (String) execution.getVariable("vehicleId");
        
        log.info("=== [FLEET STOP] User: {} | Vehicle: {} ===", userId, vehicleId);

        // Costruisci richiesta JSON
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("userId", userId);
        requestBody.put("vehicleId", vehicleId);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, String>> request = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(FLEET_URL, request, String.class);
            String responseBody = response.getBody();
            
            // Parse JSON response
            ObjectMapper mapper = new ObjectMapper();
            JsonNode json = mapper.readTree(responseBody);
            
            Double kilometers = json.get("kilometers").asDouble();
            Integer finalBattery = json.get("finalBattery").asInt();
            
            // Calcola durata in minuti
            Long startTime = (Long) execution.getVariable("rentalStartTime");
            long durationMillis = System.currentTimeMillis() - startTime;
            int durationMinutes = (int) (durationMillis / 60000);
            
            // Salva per Calculator
            execution.setVariable("kilometers", kilometers);
            execution.setVariable("finalBattery", finalBattery);
            execution.setVariable("duration", durationMinutes);
            
            log.info(" Tracking stopped - Km: {} | Battery: {}% | Duration: {}min", kilometers, finalBattery, durationMinutes);
            
        } catch (Exception e) {
            log.error(" Fleet Service unreachable", e);
        }
    }
}