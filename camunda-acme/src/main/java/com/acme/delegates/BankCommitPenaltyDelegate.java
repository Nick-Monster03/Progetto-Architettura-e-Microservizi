package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("commitPenaltyDelegate")
public class BankCommitPenaltyDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankCommitPenaltyDelegate.class);
    private static final String JOLIE_BANK_URL = "http://127.0.0.1:8008";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        Double penaltyAmount = 10.0; 
        
        log.info("=== [BANK COMMIT PENALTY] Token: {} | Amount: €{} ===", token, penaltyAmount);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <commitPenalty>\n" +
            "      <authToken>" + token + "</authToken>\n" +
            "      <penaltyAmount>" + penaltyAmount + "</penaltyAmount>\n" +
            "      <reason>Timeout scaduto - No Show</reason>\n" +
            "    </commitPenalty>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(JOLIE_BANK_URL, request, String.class);
            String responseBody = response.getBody();
            
            boolean success = responseBody != null && extractTagValue(responseBody, "success").equals("true");
            
            if (success) {
                String receiptId = extractTagValue(responseBody, "receiptId");
                execution.setVariable("penaltyReceiptId", receiptId);
                log.info("Penalty charged - Receipt: {}", receiptId);
            } else {
                log.warn("Penalty failed");
            }
            
        } catch (Exception e) {
            log.error("Error calling Bank.commitPenalty", e);
        }
    }

}