package com.acme.delegates;


import com.acme.generated.bank.PreAuthorizeResponse;
import com.acme.soap.BankSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("bankPreAuthDelegate")
public class BankPreAuthDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankPreAuthDelegate.class);
    
     @Autowired
    private BankSoapClient bankSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String userId = (String) execution.getVariable("userId");
        String card_number = (String) execution.getVariable("card_number");
        boolean isRiservation = (boolean) execution.getVariable("isRiservation");
        log.info("=== [DELEGATE] Chiamata a Jolie Bank per UserID: {} ===", userId);

        try {
            log.info("Invio richiesta di pre-autorizzazione a Jolie Bank per UserID: {}", userId);
            PreAuthorizeResponse response = bankSoapClient.preAuthorize(userId, 10.0, card_number, isRiservation);
            String responseBody = response.toString();
            log.info("Risposta da Jolie: {}", responseBody);
           

            boolean success = response.isSuccess();
            execution.setVariable("preAuthSuccess", success);


            if (success) {
                String authToken = response.getAuthToken();
                execution.setVariable("bankAuthToken", authToken);
                if(authToken != null && isRiservation){
                    long reserveStartTime = System.currentTimeMillis();
                    execution.setVariable("reserveStartTime", reserveStartTime);
                } 
                log.info("PreAuth SUCCESS - Token: {}", authToken);
            } else {
                String errorMsg = response.getErrorMessage();
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