package com.acme.delegates;

import com.acme.generated.calculator.CalculateCostResponse;
import com.acme.soap.CalculatorSoapClient;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("calculatorDelegate")
public class CalculatorDelegate implements JavaDelegate {

    private static final Logger log = LoggerFactory.getLogger(CalculatorDelegate.class);
    
    @Autowired
    private CalculatorSoapClient calculatorSoapClient;

    @Override
    public void execute(DelegateExecution execution) throws Exception {
        
        Integer duration = (Integer) execution.getVariable("duration");
        Double kilometers = (Double) execution.getVariable("kilometers");
        Integer finalBattery = (Integer) execution.getVariable("finalBattery");
        Integer latePenalty = (Integer) execution.getVariable("latePenalty");
        boolean needsPenaltyTime = (latePenalty != null && latePenalty > 0);

        log.info("=== [CALCULATOR] Duration: {}min | Km: {} | Battery: {}% ===", 
            duration, kilometers, finalBattery);

        try {
           
            CalculateCostResponse response = calculatorSoapClient.calculateCost(duration, kilometers, finalBattery, needsPenaltyTime);
            
            Double subtotal = response.getSubtotal();
            Double totalPenalty = response.getPenalty();
            Double total = response.getTotal();
            
            // Salva variabili nel processo
            execution.setVariable("subtotal", subtotal);
            execution.setVariable("totalPenalty", totalPenalty);
            execution.setVariable("total", total);
            
            log.info("Calculation complete");
            log.info("Subtotal: €{}", subtotal);
            log.info("Total Penalty: €{}", totalPenalty);
            log.info("FINAL TOTAL: €{}", total);
            
        } catch (Exception e) {
            log.error("Calculator Service unreachable", e);
            throw e;
        }
    }
}