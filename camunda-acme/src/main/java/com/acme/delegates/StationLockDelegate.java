package com.acme.delegates;

import com.acme.generated.station.LockResponse;
import com.acme.soap.StationSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("stationLockDelegate")
public class StationLockDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(StationLockDelegate.class);
    
    @Autowired
    private StationSoapClient stationSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        String vehicleId = (String) execution.getVariable("vehicleId");
        String stationId = (String) execution.getVariable("stationId");
        String userId = (String) execution.getVariable("userId");
        
        log.info("=== [STATION LOCK] VehicleID: {}, StationID: {}, UserID: {} ===", 
            vehicleId, stationId, userId);

        try {
            LockResponse response = stationSoapClient.lock(vehicleId, stationId, userId);
            
            boolean success = response.isSuccess();
            
            if (success) {
                Integer finalBattery = (int) response.getFinalBatteryLevel();
                execution.setVariable("finalBattery", finalBattery);
                
                log.info("Vehicle locked - Battery: {}%", finalBattery);
            } else {
                log.warn("Lock failed");
            }
            
        } catch (Exception e) {
            log.error("Station Service unreachable", e);
        }
    }
}