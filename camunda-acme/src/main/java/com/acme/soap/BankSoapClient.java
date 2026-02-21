package com.acme.soap;

import com.acme.generated.bank.*;

import org.apache.cxf.interceptor.transform.TransformInInterceptor;
import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import jakarta.xml.ws.Holder;

import java.util.HashMap;
import java.util.Map;

@Component
public class BankSoapClient {
    
    private static final Logger log = LoggerFactory.getLogger(BankSoapClient.class);
    private static final String BANK_SERVICE_URL = "http://127.0.0.1:8008";
    
    private BankPort bankPort;
    
    @PostConstruct
    public void init() {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(BankPort.class);
        factory.setAddress(BANK_SERVICE_URL);
        
        TransformInInterceptor transformInterceptor = new TransformInInterceptor();
        Map<String, String> transformMap = new HashMap<>();
        
        transformMap.put("preAuthorizeResponse", "{bank.acme.com.xsd}preAuthorizeResponse");
        transformMap.put("commitPaymentResponse", "{bank.acme.com.xsd}commitPaymentResponse");
        transformMap.put("commitPenaltyResponse", "{bank.acme.com.xsd}commitPenaltyResponse");
        
        transformInterceptor.setInTransformElements(transformMap);
        factory.getInInterceptors().add(transformInterceptor);
        
        bankPort = (BankPort) factory.create();
        
        log.info("Bank SOAP Client initialized at: {}", BANK_SERVICE_URL);
    }
    
   
    public PreAuthorizeResponse preAuthorize(String userId, double amount, String cardNumber, boolean isRiservation) {
        Holder<Boolean> success = new Holder<>();
        Holder<String> authTokenHolder = new Holder<>();
        Holder<String> errorMessage = new Holder<>();
        Holder<String> errorCode = new Holder<>();
        Holder<Double> blockedAmount = new Holder<>();
        
        bankPort.preAuthorize(isRiservation, amount, userId, cardNumber, 
                              success, authTokenHolder, errorMessage, errorCode, blockedAmount);
        
        PreAuthorizeResponse response = new PreAuthorizeResponse();
        response.setSuccess(success.value);
        response.setAuthToken(authTokenHolder.value);
        response.setErrorMessage(errorMessage.value);
        response.setErrorCode(errorCode.value);
        response.setBlockedAmount(blockedAmount.value);
        
        return response;
    }
    
    public void cancelAuth(String authToken, boolean isExpired, String reason) {
        bankPort.cancelAuth(reason, authToken, isExpired);
    }
    
 
    public CommitPaymentResponse commitPayment(String authToken, double finalAmount, int duration, double kilometers, int batteryLevel, Double penalty) {
        Holder<Boolean> success = new Holder<>();
        Holder<Double> chargedAmount = new Holder<>();
        Holder<String> errorMessage = new Holder<>();
        Holder<String> errorCode = new Holder<>();
        Holder<String> receiptId = new Holder<>();
        
        bankPort.commitPayment(duration, finalAmount, penalty, authToken, kilometers, batteryLevel, 
                               success, chargedAmount, errorMessage, errorCode, receiptId);
        
        CommitPaymentResponse response = new CommitPaymentResponse();
        response.setSuccess(success.value);
        response.setChargedAmount(chargedAmount.value);
        response.setErrorMessage(errorMessage.value);
        response.setErrorCode(errorCode.value);
        response.setReceiptId(receiptId.value);
        
        return response;
    }
    
   
    public CommitPenaltyResponse commitPenalty(String authToken, double penaltyAmount, String reason) {
        Holder<Boolean> success = new Holder<>();
        Holder<Double> chargedAmount = new Holder<>();
        Holder<String> errorMessage = new Holder<>();
        Holder<String> receiptId = new Holder<>();
        
        bankPort.commitPenalty(reason, authToken, penaltyAmount, 
                               success, chargedAmount, errorMessage, receiptId);
        
        CommitPenaltyResponse response = new CommitPenaltyResponse();
        response.setSuccess(success.value);
        response.setChargedAmount(chargedAmount.value);
        response.setErrorMessage(errorMessage.value);
        response.setReceiptId(receiptId.value);
        
        return response;
    }
}
