package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("stationUnlockDelegate")
public class StationUnlockDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(StationUnlockDelegate.class);
    private static final String JOLIE_STATION_URL = "http://127.0.0.1:8083";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String vehicleId = (String) execution.getVariable("vehicleId");
        String userId = (String) execution.getVariable("userId");
        String stationId = (String) execution.getVariable("stationId");
        log.info("=== [STATION UNLOCK] VehicleID: {}, UserID: {}, StationID: {} ===", vehicleId, userId, stationId);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <unlock>\n" +
            "      <vehicleId>" + vehicleId + "</vehicleId>\n" +
            "      <userId>" + userId + "</userId>\n" +
            "      <stationId>" + stationId + "</stationId>\n" +
            "    </unlock>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(JOLIE_STATION_URL, request, String.class);
            String responseBody = response.getBody();
            log.debug("DEBUG: Station Service UnLock");
            log.debug("Station Service Unlock response: {}", responseBody);
            
            boolean success = responseBody != null && responseBody.contains("<success>true</success>");
            execution.setVariable("unlockSuccess", success);
            log.info("DEBUG: Station Service UnLock");
            log.debug("Station Service response: {}", responseBody);
            log.info("Station Service response.success: {}", success);
            if (success) {
                log.info("Vehicle unlocked");
            } else {
                String errorMsg = extractTagValue(responseBody, "message");
                execution.setVariable("unlockErrorMessage", errorMsg);
                log.warn(" Unlock FAILED: {}", errorMsg);
            }
            
        } catch (Exception e) {
            log.error("Station Service unreachable", e);
            execution.setVariable("unlockSuccess", false);
            execution.setVariable("unlockErrorMessage", "Station offline");
        }
    }
}
