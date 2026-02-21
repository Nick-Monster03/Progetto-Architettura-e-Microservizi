package com.acme.delegates;

import com.acme.generated.bank.CommitPenaltyResponse;
import com.acme.soap.BankSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("commitPenaltyDelegate")
public class BankCommitPenaltyDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankCommitPenaltyDelegate.class);
    
    @Autowired
    private BankSoapClient bankSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        Double penaltyAmount = 10.0; 
        
        log.info("=== [BANK COMMIT PENALTY] Token: {} | Amount: €{} ===", token, penaltyAmount);

        

        try {
            CommitPenaltyResponse response = bankSoapClient.commitPenalty(token, penaltyAmount, "Timeout scaduto");
            
            boolean success = response.isSuccess();

            if (success) {
                String receiptId = response.getReceiptId();
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