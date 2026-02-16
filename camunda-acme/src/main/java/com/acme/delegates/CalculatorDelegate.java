package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("calculatorDelegate")
public class CalculatorDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(CalculatorDelegate.class);
    private static final String CALCULATOR_URL = "http://127.0.0.1:8089";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        Integer duration = (Integer) execution.getVariable("duration");
        Double kilometers = (Double) execution.getVariable("kilometers");
        Integer finalBattery = (Integer) execution.getVariable("finalBattery");
        Double latePenalty = (Double) execution.getVariable("latePenalty");
        boolean needsPenaltyTime = (latePenalty != null && latePenalty > 0);

        log.info("=== [CALCULATOR] Duration: {}min | Km: {} | Battery: {}% ===", 
            duration, kilometers, finalBattery);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <calculateCost>\n" +
            "      <durationMinutes>" + duration + "</durationMinutes>\n" +
            "      <kilometers>" + kilometers + "</kilometers>\n" +
            "      <finalBatteryLevel>" + finalBattery + "</finalBatteryLevel>\n" +
            "      <needsPenaltyTime>" + needsPenaltyTime + "</needsPenaltyTime>\n" +
            "    </calculateCost>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(CALCULATOR_URL, request, String.class);
            String responseBody = response.getBody();
            
            Double subtotal = extractDoubleValue(responseBody, "subtotal");
            Double totalPenalty = extractDoubleValue(responseBody, "penalty");
            Double total = extractDoubleValue(responseBody, "total");
            
            // Salva variabili nel processo
            execution.setVariable("subtotal", subtotal);
            execution.setVariable("totalPenalty", totalPenalty);
            execution.setVariable("total", total);
            
            log.info("Calculation complete");
            log.info("Subtotal: €{}", subtotal);
            log.info("Total Penalty: €{}", totalPenalty);
            log.info("FINAL TOTAL: €{}", total);
            
        } catch (Exception e) {
            log.error("Calculator Service unreachable", e);
            throw e; // Propaga errore per gestione in BPMN
        }
    }

}
