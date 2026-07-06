package com.acme.delegates;

import com.acme.generated.bank.CommitPenaltyResponse;
import com.acme.generated.station.VehicleNotAvailableFaultType_Exception;
import com.acme.generated.station.VehicleNotFoundFaultType_Exception;
import com.acme.generated.station.StationNotExistsFaultType_Exception;
import com.acme.soap.BankSoapClient;
import com.acme.soap.StationSoapClient;

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

    @Autowired
    private StationSoapClient stationSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        String vehicleId = (String) execution.getVariable("vehicleId");
        String stationId = (String) execution.getVariable("stationId");
        Boolean isRiservation = (Boolean) execution.getVariable("isRiservation");
        Double penaltyAmount = 10.0; 
        
        log.info("=== [BANK COMMIT PENALTY] Token: {} | Amount: €{} ===", token, penaltyAmount);

        if(isRiservation == null) 
        { 
            isRiservation = false; 
        }

        if (isRiservation) {
            try {
                stationSoapClient.cancelReservation(vehicleId, stationId);
                log.info("Cancel Reservation completed - vehicle {} released", vehicleId);
            } catch (VehicleNotFoundFaultType_Exception | VehicleNotAvailableFaultType_Exception | StationNotExistsFaultType_Exception e) {
                log.error("Error calling Station.cancelReservation - setting isRiservation to false", e);
                execution.setVariable("isRiservation", false);
            } catch (Exception e) {
                log.error("Error calling Station.cancelReservation", e);
                execution.setVariable("isRiservation", false);
            }
        }
        

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
            throw e;
        }
    }

}