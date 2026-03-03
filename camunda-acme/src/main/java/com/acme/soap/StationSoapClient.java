package com.acme.soap;

import com.acme.generated.station.*;

import org.apache.cxf.interceptor.transform.TransformInInterceptor;
import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import jakarta.xml.ws.Holder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class StationSoapClient {
    
    private static final Logger log = LoggerFactory.getLogger(StationSoapClient.class);
    private static final String STATION_SERVICE_URL = "http://127.0.0.1:8083";
    
    private StationPort stationPort;
    
    @PostConstruct
    public void init() {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(StationPort.class);
        factory.setAddress(STATION_SERVICE_URL);
        
        TransformInInterceptor transformInterceptor = new TransformInInterceptor();
        Map<String, String> transformMap = new HashMap<>();
        
        transformMap.put("getAllStationsResponse", "{station.acme.com.xsd}getAllStationsResponse");
        transformMap.put("unlockResponse", "{station.acme.com.xsd}unlockResponse");
        transformMap.put("lockResponse", "{station.acme.com.xsd}lockResponse");
        
        transformInterceptor.setInTransformElements(transformMap);
        factory.getInInterceptors().add(transformInterceptor);

        stationPort = (StationPort) factory.create();
        
        log.info("Station SOAP Client initialized at: {}", STATION_SERVICE_URL);
    }

    
    public List<StationInfo> getAllStations() {
        return stationPort.getAllStations();
    }
    
    
    public UnlockResponse unlock(String vehicleId, String userId, String stationId) 
            throws VehicleNotAvailableFaultType_Exception, VehicleNotFoundFaultType_Exception, HardwareErrorFaultType_Exception {
        
        Holder<Boolean> success = new Holder<>();
        Holder<String> message = new Holder<>();
        
        stationPort.unlock(vehicleId, userId, stationId, success, message);
        
        UnlockResponse response = new UnlockResponse();
        response.setSuccess(success.value);
        response.setMessage(message.value);
        
        return response;
    }
    
    
    public LockResponse lock(String vehicleId, String stationId, String userId) 
            throws VehicleNotFoundFaultType_Exception, HardwareErrorFaultType_Exception {
        
        Holder<Double> finalBatteryLevel = new Holder<>();
        Holder<Boolean> success = new Holder<>();
        Holder<String> message = new Holder<>();
        
        stationPort.lock(vehicleId, userId, stationId, finalBatteryLevel, success, message);
        
        LockResponse response = new LockResponse();
        response.setFinalBatteryLevel(finalBatteryLevel.value);
        response.setSuccess(success.value);
        response.setMessage(message.value);
        
        return response;
    }
}
