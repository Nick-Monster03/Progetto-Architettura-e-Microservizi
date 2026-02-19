package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("stationLockDelegate")
public class StationLockDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(StationLockDelegate.class);
    private static final String JOLIE_STATION_URL = "http://127.0.0.1:8083";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String vehicleId = (String) execution.getVariable("vehicleId");
        String stationId = (String) execution.getVariable("stationId");
        String userId = (String) execution.getVariable("userId");
        log.info("=== [STATION LOCK] VehicleID: {}, StationID: {}, UserID: {} ===", vehicleId, stationId, userId);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <lock>\n" +
            "      <vehicleId>" + vehicleId + "</vehicleId>\n" +
            "      <stationId>" + stationId + "</stationId>\n" +
            "      <userId>" + userId + "</userId>\n" +
            "    </lock>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(JOLIE_STATION_URL, request, String.class);
            String responseBody = response.getBody();
            log.debug("DEBUG: Station Service Lock");
            log.debug("Station Service Lock response: {}", responseBody);
            boolean success = responseBody != null && extractTagValue(responseBody, "success").equals("true");
            log.info("DEBUG: Station Service Lock");
            log.info("Station Service response.success: {}", success);
            if (success) {
                // Estrai batteria finale
                Integer finalBattery = extractIntValue(responseBody, "finalBatteryLevel");
                execution.setVariable("finalBattery", finalBattery);
                
                log.info(" Vehicle locked - Battery: {}%", finalBattery);
            } else {
                log.warn("Lock failed");
            }
            
        } catch (Exception e) {
            log.error("Station Service unreachable", e);
        }
    }

}