package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("commitPaymentDelegate")
public class BankCommitPaymentDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankCommitPaymentDelegate.class);
    private static final String JOLIE_BANK_URL = "http://127.0.0.1:8008";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        Double finalAmount = (Double) execution.getVariable("total");
        Integer duration = (Integer) execution.getVariable("duration");
        Double kilometers = (Double) execution.getVariable("kilometers");
        Integer finalBattery = (Integer) execution.getVariable("finalBattery");
        Double totalPenalty = (Double) execution.getVariable("totalPenalty");
        
        log.info("=== [BANK COMMIT PAYMENT] ===");
        log.info("Token: {}", token);
        log.info("Final Amount: €{}", finalAmount);
        log.info("Duration: {} min", duration);
        log.info("Kilometers: {}", kilometers);
        log.info("Final Battery: {}%", finalBattery);
        log.info("Total Penalty: €{}", totalPenalty);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <commitPayment>\n" +
            "      <authToken>" + token + "</authToken>\n" +
            "      <finalAmount>" + finalAmount + "</finalAmount>\n" +
            "      <duration>" + duration + "</duration>\n" +
            "      <kilometers>" + kilometers + "</kilometers>\n" +
            "      <batteryLevel>" + finalBattery + "</batteryLevel>\n" +
            "      <penalty>" + totalPenalty + "</penalty>\n" +
            "    </commitPayment>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(JOLIE_BANK_URL, request, String.class);
            String responseBody = response.getBody();
            log.debug("DEBUG: Bank Service commitPayment");
            log.debug("Bank Service response: {}", responseBody);
            boolean success = responseBody != null && extractTagValue(responseBody, "success").equals("true");
            
            execution.setVariable("paymentSuccess", success);
            log.info("DEBUG: Bank Service commitPayment - Success: {}", success);
            log.info("Bank Service response.success: {}", success);
            if (success) {
                String receiptId = extractTagValue(responseBody, "receiptId");
                execution.setVariable("paymentReceiptId", receiptId);
                log.info("Payment SUCCESS - Receipt: {}", receiptId);
            } else {
                String errorMsg = extractTagValue(responseBody, "errorMessage");
                execution.setVariable("paymentErrorMessage", errorMsg);
                log.warn("Payment FAILED: {}", errorMsg);
            }
            
        } catch (Exception e) {
            log.error("Error calling Bank.commitPayment", e);
            execution.setVariable("paymentSuccess", false);
            execution.setVariable("paymentErrorMessage", "Bank offline");
            throw e;
        }
    }
}