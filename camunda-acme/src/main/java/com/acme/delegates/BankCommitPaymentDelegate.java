package com.acme.delegates;

import com.acme.generated.bank.CommitPaymentResponse;
import com.acme.soap.BankSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("commitPaymentDelegate")
public class BankCommitPaymentDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankCommitPaymentDelegate.class);
    
    @Autowired
    private BankSoapClient bankSoapClient;

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

        try {
            CommitPaymentResponse response = bankSoapClient.commitPayment(
                token,
                finalAmount != null ? finalAmount : 0.0,
                duration != null ? duration : 0,
                kilometers != null ? kilometers : 0.0,
                finalBattery != null ? finalBattery : 0,
                totalPenalty != null ? totalPenalty : 0.0
            );
            
            boolean success = response.isSuccess();
            execution.setVariable("paymentSuccess", success);
            
            if (success) {
                String receiptId = response.getReceiptId();
                execution.setVariable("paymentReceiptId", receiptId);
                log.info("Payment SUCCESS - Receipt: {}", receiptId);
            } else {
                String errorMsg = response.getErrorMessage();
                execution.setVariable("paymentErrorMessage", errorMsg);
                log.warn("Payment FAILED: {}", errorMsg);
            }
            
        } catch (Exception e) {
            log.error("Error calling Bank.commitPayment", e);
            execution.setVariable("paymentSuccess", false);
            execution.setVariable("paymentErrorMessage", "Bank offline");
        }
    }
}