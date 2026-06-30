package com.acme.soap;

import com.acme.generated.bank.*;

import org.apache.cxf.interceptor.transform.TransformInInterceptor;
import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import jakarta.xml.ws.Holder;

import java.util.HashMap;
import java.util.Map;

@Component
public class BankSoapClient {

    private static final Logger log = LoggerFactory.getLogger(BankSoapClient.class);

    @Value("${services.bank.url}")
    private String bankServiceUrl;

    private BankPort bankPort;

    @PostConstruct
    public void init() {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(BankPort.class);
        factory.setAddress(bankServiceUrl);

        TransformInInterceptor transformInterceptor = new TransformInInterceptor();
        Map<String, String> transformMap = new HashMap<>();
        transformMap.put("preAuthorizeResponse",  "{http://bank.acme.mobility.wsdl.xsd}preAuthorizeResponse");
        transformMap.put("commitPaymentResponse", "{http://bank.acme.mobility.wsdl.xsd}commitPaymentResponse");
        transformMap.put("commitPenaltyResponse", "{http://bank.acme.mobility.wsdl.xsd}commitPenaltyResponse");
        transformInterceptor.setInTransformElements(transformMap);
        factory.getInInterceptors().add(transformInterceptor);

        bankPort = (BankPort) factory.create();
        log.info("Bank SOAP Client inizializzato su: {}", bankServiceUrl);
    }

    // ── preAuthorize ────────────────────────────────────────────────────────
    // Firma CXF: (boolean isRiservation, double amount, String userId,
    //             String cardNumber, Holder<Boolean> success,
    //             Holder<String> authToken, Holder<String> errorMessage,
    //             Holder<String> errorCode, Holder<Double> blockedAmount)
    public PreAuthorizeResponse preAuthorize(String userId, String vehicleId, double amount,
                                              String cardNumber, boolean isReservation) {
        Holder<Boolean> success       = new Holder<>();
        Holder<String>  authToken     = new Holder<>();
        Holder<String>  errorMessage  = new Holder<>();
        Holder<String>  errorCode     = new Holder<>();
        Holder<Double>  blockedAmount = new Holder<>();

        bankPort.preAuthorize(isReservation, amount, vehicleId, userId, cardNumber,
                              success, authToken, errorMessage, errorCode, blockedAmount);

        PreAuthorizeResponse resp = new PreAuthorizeResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setAuthToken(authToken.value);
        resp.setErrorMessage(errorMessage.value);
        resp.setErrorCode(errorCode.value);
        resp.setBlockedAmount(blockedAmount.value != null ? blockedAmount.value : 0.0);
        return resp;
    }

    // ── commitPayment ───────────────────────────────────────────────────────
    // Firma CXF: (int duration, double finalAmount, Double penalty,
    //             String authToken, double kilometers, int batteryLevel,
    //             Holder<Boolean> success, Holder<Double> chargedAmount,
    //             Holder<String> errorMessage, Holder<String> errorCode,
    //             Holder<String> receiptId)
    public CommitPaymentResponse commitPayment(String authToken, double finalAmount,
                                            int duration, double kilometers,
                                            int batteryLevel, Double penalty) {
        Holder<Boolean> success       = new Holder<>();
        Holder<Double>  chargedAmount = new Holder<>();
        Holder<String>  errorMessage  = new Holder<>();
        Holder<String>  errorCode     = new Holder<>();
        Holder<String>  receiptId     = new Holder<>();

        bankPort.commitPayment(duration, finalAmount, penalty, authToken, kilometers, batteryLevel,
                               success, chargedAmount, errorMessage, errorCode, receiptId);

        CommitPaymentResponse resp = new CommitPaymentResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setChargedAmount(chargedAmount.value != null ? chargedAmount.value : 0.0);
        resp.setErrorMessage(errorMessage.value);
        resp.setErrorCode(errorCode.value);
        resp.setReceiptId(receiptId.value);
        return resp;
    }

    // ── commitPenalty ───────────────────────────────────────────────────────
    // Firma CXF: (String reason, String authToken, double penaltyAmount,
    //             Holder<Boolean> success, Holder<Double> chargedAmount,
    //             Holder<String> errorMessage, Holder<String> receiptId)
    public CommitPenaltyResponse commitPenalty(String authToken, double penaltyAmount,
                                                String reason) {
        Holder<Boolean> success       = new Holder<>();
        Holder<Double>  chargedAmount = new Holder<>();
        Holder<String>  errorMessage  = new Holder<>();
        Holder<String>  receiptId     = new Holder<>();

        bankPort.commitPenalty(reason, authToken, penaltyAmount,
                               success, chargedAmount, errorMessage, receiptId);

        CommitPenaltyResponse resp = new CommitPenaltyResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setChargedAmount(chargedAmount.value != null ? chargedAmount.value : 0.0);
        resp.setErrorMessage(errorMessage.value);
        resp.setReceiptId(receiptId.value);
        return resp;
    }

    // ── cancelAuth ──────────────────────────────────────────────────────────
    // Firma CXF: (String reason, String authToken, boolean isExpired)  — @Oneway
    public void cancelAuth(String authToken, String reason, boolean isExpired) {
        bankPort.cancelAuth(reason, authToken, isExpired);
    }
}