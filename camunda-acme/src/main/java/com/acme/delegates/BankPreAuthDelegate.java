package com.acme.delegates;

import static com.acme.delegates.extractTagValue.*;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

@Component("bankPreAuthDelegate")
public class BankPreAuthDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankPreAuthDelegate.class);
    
    // Indirizzo del tuo servizio Jolie
    private static final String JOLIE_BANK_URL = "http://127.0.0.1:8008";

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String userId = (String) execution.getVariable("userId");
        String card_number = (String) execution.getVariable("card_number");
        boolean isRiservation = (boolean) execution.getVariable("isRiservation");
        log.info("=== [DELEGATE] Chiamata a Jolie Bank per UserID: {} ===", userId);

        String soapRequest = 
            "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
            "  <SOAP-ENV:Body>\n" +
            "    <preAuthorize>\n" +
            "      <userId>" + userId + "</userId>\n" +
            "      <amount>10.0</amount>\n" +
            "      <cardNumber>" + card_number + "</cardNumber>\n" +
            "      <isRiservation>" + isRiservation + "</isRiservation>\n" +
            "    </preAuthorize>\n" +
            "  </SOAP-ENV:Body>\n" +
            "</SOAP-ENV:Envelope>";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_XML);
        HttpEntity<String> request = new HttpEntity<>(soapRequest, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(JOLIE_BANK_URL, request, String.class);
            String responseBody = response.getBody();
            log.info("Risposta da Jolie: {}", responseBody);
           

            boolean success = responseBody != null && extractTagValue(responseBody, "success").equals("true");
            
            execution.setVariable("preAuthSuccess", success);


            if (success) {
                String authToken = extractTagValue(responseBody, "authToken");
                execution.setVariable("bankAuthToken", authToken);
                if(authToken != null && isRiservation){
                    long reserveStartTime = System.currentTimeMillis();
                    execution.setVariable("reserveStartTime", reserveStartTime);
                } 
                log.info("PreAuth SUCCESS - Token: {}", authToken);
            } else {
                String errorMsg = extractTagValue(responseBody, "errorMessage");
                execution.setVariable("preAuthErrorMessage", errorMsg != null ? errorMsg : "Errore generico Bank");
                log.warn("PreAuth fallita per utente: {}", userId);
            }

        } catch (Exception e) {
            log.error("Errore di connessione a Jolie Bank Service: ", e);
            execution.setVariable("preAuthSuccess", false);
            execution.setVariable("preAuthErrorMessage", "Servizio Bank offline");
        }
    }

}