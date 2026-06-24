package com.acme.delegates;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Component("fleetGetStatusDelegate")
public class FleetGetStatusDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(FleetGetStatusDelegate.class);
    private static final String FLEET_URL = "http://fleet-gateway:8082/getStatus";

    @Override
    public void execute(DelegateExecution execution) throws Exception {

        String vehicleId = (String) execution.getVariable("vehicleId");

        String url = UriComponentsBuilder.fromHttpUrl(FLEET_URL)
                .queryParam("vehicleId", vehicleId)
                .toUriString();

        RestTemplate restTemplate = new RestTemplate();
        ResponseEntity<String> response;
        try {
            response = restTemplate.getForEntity(url, String.class);
        } catch (Exception e) {
            log.warn("FleetGateway irraggiungibile durante getStatus per vehicle {}", vehicleId, e);
            execution.setVariable("getStatusSuccess", false);
            execution.setVariable("batteryLevel", -1);
            return;
        }

        ObjectMapper mapper = new ObjectMapper();
        JsonNode json = mapper.readTree(response.getBody());
        boolean success = json.path("success").asBoolean(false);
        execution.setVariable("getStatusSuccess", success);

        if (success) {
            int batteryLevel = json.path("batteryLevel").asInt(-1);
            execution.setVariable("batteryLevel", batteryLevel);
            execution.setVariable("latitude", json.path("latitude").asDouble(0.0));
            execution.setVariable("longitude", json.path("longitude").asDouble(0.0));
            execution.setVariable("vehicleStatus", json.path("status").asText(""));
            log.info("getStatus OK - vehicle {}: battery={}%", vehicleId, batteryLevel);
        } else {
            execution.setVariable("batteryLevel", -1);
            log.warn("getStatus fallito per vehicle {}: {}", vehicleId, json.path("message").asText(""));
        }
    }
}
