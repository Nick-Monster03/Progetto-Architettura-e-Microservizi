package com.acme.soap;

import com.acme.generated.calculator.*;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.apache.cxf.interceptor.transform.TransformInInterceptor;
import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import jakarta.xml.ws.Holder;

@Component
public class CalculatorSoapClient {
    
    private static final Logger log = LoggerFactory.getLogger(CalculatorSoapClient.class);
    @Value("${services.calculator.url}")
    private String calculatorServiceUrl;
    
    private CalculatorPort calculatorPort;
    
    @PostConstruct
    public void init() {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(CalculatorPort.class);
        factory.setAddress(calculatorServiceUrl);


        

        TransformInInterceptor transformInterceptor = new TransformInInterceptor();
        Map<String, String> transformMap = new HashMap<>();
        
        transformMap.put("calculateCostResponse", "{calculator.acme.com.xsd}calculateCostResponse");
        
        transformInterceptor.setInTransformElements(transformMap);
        factory.getInInterceptors().add(transformInterceptor);
        
        calculatorPort = (CalculatorPort) factory.create();
        
        log.info("Calculator SOAP Client initialized at: {}", calculatorServiceUrl);
    }
    
    /**
     * Calcola costo noleggio
     */
    public CalculateCostResponse calculateCost(double durationMinutes, double kilometers, 
                                                int finalBatteryLevel, boolean needsPenaltyTime) {
        
        // 1. Inizializza gli Holder per i 5 valori di output
        Holder<Double> total = new Holder<>();
        Holder<Double> subtotal = new Holder<>();
        Holder<Double> penalty = new Holder<>();
        Holder<Double> basePriceDistance = new Holder<>();
        Holder<Double> basePriceTime = new Holder<>();
        
        // 2. Chiama l'operazione rispettando l'ordine ESATTO dei parametri di CalculatorPort
        calculatorPort.calculateCost(
            needsPenaltyTime, 
            durationMinutes, 
            finalBatteryLevel, 
            kilometers, 
            total, 
            subtotal, 
            penalty, 
            basePriceDistance, 
            basePriceTime
        );
        
        // 3. Popola l'oggetto response usando i valori estratti dagli Holder
        CalculateCostResponse response = new CalculateCostResponse();
        response.setTotal(total.value);
        response.setSubtotal(subtotal.value);
        response.setPenalty(penalty.value);
        response.setBasePriceDistance(basePriceDistance.value);
        response.setBasePriceTime(basePriceTime.value);
        
        return response;
    }
}
