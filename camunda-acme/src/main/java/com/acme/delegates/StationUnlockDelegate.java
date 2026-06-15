package com.acme.delegates;

import com.acme.generated.station.UnlockResponse;
import com.acme.soap.StationSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("stationUnlockDelegate")
public class StationUnlockDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(StationUnlockDelegate.class);
    
    @Autowired
    private StationSoapClient stationSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String vehicleId = (String) execution.getVariable("vehicleId");
        String userId = (String) execution.getVariable("userId");
        String stationId = (String) execution.getVariable("stationId");
        
        log.info("=== [STATION UNLOCK] VehicleID: {}, UserID: {}, StationID: {} ===", 
            vehicleId, userId, stationId);

        try {
            UnlockResponse response = stationSoapClient.unlock(vehicleId, userId, stationId);
            
            boolean success = response.isSuccess();
            execution.setVariable("unlockSuccess", success);
            
            if (success) {
                log.info("Vehicle unlocked");
            } else {
                String errorMsg = response.getMessage();
                execution.setVariable("unlockErrorMessage", errorMsg);
                log.warn("Unlock FAILED: {}", errorMsg);
            }
            
        }
        catch (jakarta.xml.ws.soap.SOAPFaultException e) {
            // Fault SOAP dalla stazione (veicolo non disponibile, broken, ecc.)
            log.warn("Unlock rifiutato dalla stazione: {}", e.getMessage());
            execution.setVariable("unlockSuccess", false);
            execution.setVariable("unlockErrorMessage", e.getMessage());
        } 
        catch (Exception e) {
            log.error("Station Service unreachable", e);
            execution.setVariable("unlockSuccess", false);
            execution.setVariable("unlockErrorMessage", "Station offline");
        }
    }
}