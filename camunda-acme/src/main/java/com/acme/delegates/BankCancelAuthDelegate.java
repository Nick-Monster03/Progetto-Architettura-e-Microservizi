package com.acme.delegates;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Component("cancelAuthDelegate")
public class BankCancelAuthDelegate implements JavaDelegate{
    private static final Logger log = LoggerFactory.getLogger(BankCancelAuthDelegate.class);
    private static final String JOLIE_BANK_URL = "http://127.0.0.1:8008";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        Boolean isExpired = (Boolean) execution.getVariable("cancelisExpired");
        
        // Default: false se variabile non esiste (StartRental immediato)
        if (isExpired == null) {
            isExpired = false;
        }
        
        log.info("=== [BANK CANCEL AUTH] Token: {} | isExpired: {} ===", token, isExpired);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <cancelAuth>\n" +
            "      <authToken>" + token + "</authToken>\n" +
            "      <isExpired>" + isExpired + "</isExpired>\n" +
            "      <reason>User cancellation</reason>\n" +
            "    </cancelAuth>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            // OneWay operation - no response expected
            restTemplate.postForEntity(JOLIE_BANK_URL, request, String.class);
            log.info("Cancel Auth completed");
            
        } catch (Exception e) {
            log.error(" Error calling Bank.cancelAuth", e);
            // OneWay - non blocchiamo il processo anche se fallisce
        }
    }
}
