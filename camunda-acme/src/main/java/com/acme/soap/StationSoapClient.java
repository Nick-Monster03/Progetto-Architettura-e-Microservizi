package com.acme.soap;

import com.acme.generated.station.*;

import org.apache.cxf.interceptor.transform.TransformInInterceptor;
import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import jakarta.xml.ws.Holder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class StationSoapClient {

    private static final Logger log = LoggerFactory.getLogger(StationSoapClient.class);

    @Value("${services.station.url}")
    private String stationServiceUrl;

    private StationPort stationPort;

    @PostConstruct
    public void init() {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(StationPort.class);
        factory.setAddress(stationServiceUrl);

        TransformInInterceptor transformInterceptor = new TransformInInterceptor();
        Map<String, String> transformMap = new HashMap<>();
        transformMap.put("getAllStationsResponse",      "{http://acmemobility.org/station.xsd}getAllStationsResponse");
        transformMap.put("unlockResponse",              "{http://acmemobility.org/station.xsd}unlockResponse");
        transformMap.put("lockResponse",                "{http://acmemobility.org/station.xsd}lockResponse");
        transformMap.put("reserveResponse",             "{http://acmemobility.org/station.xsd}reserveResponse");
        transformMap.put("cancelReservationResponse",   "{http://acmemobility.org/station.xsd}cancelReservationResponse");
        transformInterceptor.setInTransformElements(transformMap);
        factory.getInInterceptors().add(transformInterceptor);

        stationPort = (StationPort) factory.create();
        log.info("Station SOAP Client inizializzato su: {}", stationServiceUrl);
    }

    // ── getAllStations ───────────────────────────────────────────────────────
    // Firma CXF: (String request) → List<StationInfo>
    public List<StationInfo> getAllStations() {
        return stationPort.getAllStations();
    }

    // ── unlock ───────────────────────────────────────────────────────────────
    // Firma CXF: (String vehicleId, String userId, String stationId,
    //             Holder<Boolean> success, Holder<String> message)
    public UnlockResponse unlock(String vehicleId, String userId, String stationId)
            throws VehicleNotAvailableFaultType_Exception,
                   VehicleNotFoundFaultType_Exception,
                   HardwareErrorFaultType_Exception,
                   StationNotExistsFaultType_Exception,
                   InvalidRequestFaultType_Exception {

        Holder<Boolean> success = new Holder<>();
        Holder<String>  message = new Holder<>();

        stationPort.unlock(vehicleId, userId, stationId, success, message);

        UnlockResponse resp = new UnlockResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setMessage(message.value);
        return resp;
    }

    // ── lock ─────────────────────────────────────────────────────────────────
    // Firma CXF: (String vehicleId, String userId, String stationId,
    //             Holder<Double> finalBatteryLevel,
    //             Holder<Boolean> success, Holder<String> message)
    public LockResponse lock(String vehicleId, String stationId, String userId)
            throws VehicleNotFoundFaultType_Exception,
                   HardwareErrorFaultType_Exception,
                   StationNotExistsFaultType_Exception,
                   InvalidRequestFaultType_Exception {

        Holder<Double>  finalBatteryLevel = new Holder<>();
        Holder<Boolean> success           = new Holder<>();
        Holder<String>  message           = new Holder<>();

        stationPort.lock(vehicleId, userId, stationId, finalBatteryLevel, success, message);

        LockResponse resp = new LockResponse();
        resp.setFinalBatteryLevel(finalBatteryLevel.value != null ? finalBatteryLevel.value : 0.0);
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setMessage(message.value);
        return resp;
    }

    public ReserveResponse reserve(String vehicleId, String stationId, String userId)
            throws VehicleNotFoundFaultType_Exception,
                   StationNotExistsFaultType_Exception,
                   VehicleNotAvailableFaultType_Exception {

        Holder<Boolean> success = new Holder<>();
        Holder<String>  message = new Holder<>();

        stationPort.reserve(vehicleId, userId, stationId, success, message);

        ReserveResponse resp = new ReserveResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setMessage(message.value);
        return resp;
    }

    // ── cancelReservation ───────────────────────────────────────────────────
    public CancelReservationResponse cancelReservation(String vehicleId, String stationId)
            throws VehicleNotFoundFaultType_Exception,
                   VehicleNotAvailableFaultType_Exception,
                   StationNotExistsFaultType_Exception {

        Holder<Boolean> success = new Holder<>();
        Holder<String>  message = new Holder<>();

        stationPort.cancelReservation(vehicleId, stationId, success, message);

        CancelReservationResponse resp = new CancelReservationResponse();
        resp.setSuccess(Boolean.TRUE.equals(success.value));
        resp.setMessage(message.value);
        return resp;
    }
}