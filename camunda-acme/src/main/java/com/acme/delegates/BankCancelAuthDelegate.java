package com.acme.delegates;
import com.acme.soap.BankSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("cancelAuthDelegate")
public class BankCancelAuthDelegate implements JavaDelegate{
    private static final Logger log = LoggerFactory.getLogger(BankCancelAuthDelegate.class);
    
    @Autowired
    private BankSoapClient bankSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        Boolean isExpired = (Boolean) execution.getVariable("cancelisExpired");
        
        // Default: false se variabile non esiste (StartRental immediato)
        if (isExpired == null) {
            isExpired = false;
        }
        
        log.info("=== [BANK CANCEL AUTH] Token: {} | isExpired: {} ===", token, isExpired);

        try {

            bankSoapClient.cancelAuth(token, isExpired, "User cancellation");
            log.info("Cancel Auth completed");
            
        } catch (Exception e) {
            log.error(" Error calling Bank.cancelAuth", e);
            // OneWay - non blocchiamo il processo anche se fallisce
        }
    }
}
