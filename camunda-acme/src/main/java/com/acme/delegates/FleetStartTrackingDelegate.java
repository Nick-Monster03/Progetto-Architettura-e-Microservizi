package com.acme.delegates;

import java.util.HashMap;
import java.util.Map;

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
    //private static final String FLEET_URL = "http://127.0.0.1:8082/startTracking";
    private static final String FLEET_URL = "http://fleet-gateway:8082/startTracking";
    
    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String userId = (String) execution.getVariable("userId");
        String vehicleId = (String) execution.getVariable("vehicleId");
        
        log.info("=== [FLEET START] User: {} | Vehicle: {} ===", userId, vehicleId);

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
            
            log.info("Tracking started");
            
            // Salva timestamp inizio viaggio
            long rentalStartTime = System.currentTimeMillis();
            execution.setVariable("rentalStartTime", rentalStartTime);
            
        } catch (Exception e) {
            log.error("Fleet Service unreachable", e);
        }
    }
}