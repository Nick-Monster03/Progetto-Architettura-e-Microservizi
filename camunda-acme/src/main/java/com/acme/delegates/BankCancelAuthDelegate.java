package com.acme.delegates;
import com.acme.generated.station.StationNotExistsFaultType_Exception;
import com.acme.generated.station.VehicleNotAvailableFaultType_Exception;
import com.acme.generated.station.VehicleNotFoundFaultType_Exception;
import com.acme.soap.BankSoapClient;
import com.acme.soap.StationSoapClient;

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

    @Autowired
    private StationSoapClient stationSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String token = (String) execution.getVariable("bankAuthToken");
        String vehicleId = (String) execution.getVariable("vehicleId");
        String stationId = (String) execution.getVariable("stationId");
        Boolean isExpired = (Boolean) execution.getVariable("cancelisExpired");
        Boolean isRiservation = (Boolean) execution.getVariable("isRiservation");
        
        // Default: false se variabile non esiste (StartRental immediato)
        if (isExpired == null) {
            isExpired = false;
        }
        if (isRiservation == null) {
            isRiservation = false;
        }
        
        log.info("=== [BANK CANCEL AUTH] Token: {} | isExpired: {} ===", token, isExpired);

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

            bankSoapClient.cancelAuth(token, "User cancellation", isExpired);
            log.info("Cancel Auth completed");
            
        } catch (Exception e) {
            log.error(" Error calling Bank.cancelAuth", e);
            // OneWay - non blocchiamo il processo anche se fallisce
        }


    }
}
