package com.acme.delegates;

import com.acme.generated.bank.PreAuthorizeResponse;
import com.acme.generated.station.ReserveResponse;
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

@Component("bankPreAuthDelegate")
public class BankPreAuthDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(BankPreAuthDelegate.class);

    @Autowired
    private BankSoapClient bankSoapClient;

    @Autowired
    private StationSoapClient stationSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {

        String userId = (String) execution.getVariable("userId");
        String vehicleId = (String) execution.getVariable("vehicleId");
        String stationId = (String) execution.getVariable("stationId");
        String card_number = (String) execution.getVariable("card_number");
        Boolean isRiservation = (Boolean) execution.getVariable("isRiservation");
        if (isRiservation == null) {
            isRiservation = false;
        }

        // default di sicurezza: se il blocco reserve sotto non viene mai eseguito,
        // il gateway ReserveIsOk deve comunque trovare un valore
        execution.setVariable("reserveSuccess", true);

        log.info("=== [DELEGATE] Chiamata a Jolie Bank per UserID: {} ===", userId);

        try {
            PreAuthorizeResponse response = bankSoapClient.preAuthorize(userId, vehicleId, 10.0, card_number, isRiservation);
            log.info("Risposta da Jolie: {}", response);

            boolean preAuthSuccess = response.isSuccess();

            if (preAuthSuccess) {
                String authToken = response.getAuthToken();
                execution.setVariable("bankAuthToken", authToken);
                log.info("PreAuth SUCCESS per utente: {}", userId);

                if (isRiservation) {
                    if (authToken != null) {
                        try {
                            ReserveResponse stationReserveResponse = stationSoapClient.reserve(vehicleId, stationId, userId);
                            if (stationReserveResponse.isSuccess()) {
                                execution.setVariable("reserveSuccess", true);
                                execution.setVariable("reserveStartTime", System.currentTimeMillis());
                                log.info("Vehicle {} successfully reserved at station {}", vehicleId, stationId);
                            } else {
                                log.warn("Station reserve failed for vehicle {} at station {}: {}",
                                        vehicleId, stationId, stationReserveResponse.getMessage());
                                execution.setVariable("reserveSuccess", false);
                                execution.setVariable("isRiservation", false);
                            }
                        } catch (VehicleNotFoundFaultType_Exception | StationNotExistsFaultType_Exception
                                 | VehicleNotAvailableFaultType_Exception e) {
                            log.warn("Station ha rifiutato reserve per vehicle {}: {}", vehicleId, e.getMessage());
                            execution.setVariable("reserveSuccess", false);
                            execution.setVariable("isRiservation", false);
                        } catch (Exception e) {
                            log.error("Error calling Station.reserve", e);
                            execution.setVariable("reserveSuccess", false);
                            execution.setVariable("isRiservation", false);
                        }
                    } else {
                        log.error("authToken nullo nonostante preAuthSuccess=true: reserve non tentata");
                        execution.setVariable("reserveSuccess", false);
                        execution.setVariable("isRiservation", false);
                    }
                }
            } else {
                String errorMsg = response.getErrorMessage();
                execution.setVariable("preAuthErrorMessage", errorMsg != null ? errorMsg : "Errore generico Bank");
                log.warn("PreAuth fallita per utente: {}", userId);
            }

            execution.setVariable("preAuthSuccess", preAuthSuccess);

        } catch (Exception e) {
            log.error("Errore di connessione a Jolie Bank Service: ", e);
            execution.setVariable("preAuthSuccess", false);
            execution.setVariable("preAuthErrorMessage", "Servizio Bank offline");
        }
    }
}