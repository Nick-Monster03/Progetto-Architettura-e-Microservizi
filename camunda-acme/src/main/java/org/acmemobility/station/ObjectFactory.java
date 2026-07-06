
package org.acmemobility.station;

import jakarta.xml.bind.annotation.XmlRegistry;


/**
 * This object contains factory methods for each 
 * Java content interface and Java element interface 
 * generated in the org.acmemobility.station package. 
 * <p>An ObjectFactory allows you to programatically 
 * construct new instances of the Java representation 
 * for XML content. The Java representation of XML 
 * content can consist of schema derived interfaces 
 * and classes representing the binding of schema 
 * type definitions, element declarations and model 
 * groups.  Factory methods for each of these are 
 * provided in this class.
 * 
 */
@XmlRegistry
public class ObjectFactory {


    /**
     * Create a new ObjectFactory that can be used to create new instances of schema derived classes for package: org.acmemobility.station
     * 
     */
    public ObjectFactory() {
    }

    /**
     * Create an instance of {@link Unlock }
     * 
     */
    public Unlock createUnlock() {
        return new Unlock();
    }

    /**
     * Create an instance of {@link UnlockResponse }
     * 
     */
    public UnlockResponse createUnlockResponse() {
        return new UnlockResponse();
    }

    /**
     * Create an instance of {@link HardwareErrorFaultType }
     * 
     */
    public HardwareErrorFaultType createHardwareErrorFaultType() {
        return new HardwareErrorFaultType();
    }

    /**
     * Create an instance of {@link InvalidRequestFaultType }
     * 
     */
    public InvalidRequestFaultType createInvalidRequestFaultType() {
        return new InvalidRequestFaultType();
    }

    /**
     * Create an instance of {@link StationNotExistsFaultType }
     * 
     */
    public StationNotExistsFaultType createStationNotExistsFaultType() {
        return new StationNotExistsFaultType();
    }

    /**
     * Create an instance of {@link VehicleNotAvailableFaultType }
     * 
     */
    public VehicleNotAvailableFaultType createVehicleNotAvailableFaultType() {
        return new VehicleNotAvailableFaultType();
    }

    /**
     * Create an instance of {@link VehicleNotFoundFaultType }
     * 
     */
    public VehicleNotFoundFaultType createVehicleNotFoundFaultType() {
        return new VehicleNotFoundFaultType();
    }

    /**
     * Create an instance of {@link GetStationByVehicleId }
     * 
     */
    public GetStationByVehicleId createGetStationByVehicleId() {
        return new GetStationByVehicleId();
    }

    /**
     * Create an instance of {@link GetStationByVehicleIdResponse }
     * 
     */
    public GetStationByVehicleIdResponse createGetStationByVehicleIdResponse() {
        return new GetStationByVehicleIdResponse();
    }

    /**
     * Create an instance of {@link GetVehicles }
     * 
     */
    public GetVehicles createGetVehicles() {
        return new GetVehicles();
    }

    /**
     * Create an instance of {@link GetVehiclesResponse }
     * 
     */
    public GetVehiclesResponse createGetVehiclesResponse() {
        return new GetVehiclesResponse();
    }

    /**
     * Create an instance of {@link CancelReservation }
     * 
     */
    public CancelReservation createCancelReservation() {
        return new CancelReservation();
    }

    /**
     * Create an instance of {@link CancelReservationResponse }
     * 
     */
    public CancelReservationResponse createCancelReservationResponse() {
        return new CancelReservationResponse();
    }

    /**
     * Create an instance of {@link Reserve }
     * 
     */
    public Reserve createReserve() {
        return new Reserve();
    }

    /**
     * Create an instance of {@link ReserveResponse }
     * 
     */
    public ReserveResponse createReserveResponse() {
        return new ReserveResponse();
    }

    /**
     * Create an instance of {@link Lock }
     * 
     */
    public Lock createLock() {
        return new Lock();
    }

    /**
     * Create an instance of {@link LockResponse }
     * 
     */
    public LockResponse createLockResponse() {
        return new LockResponse();
    }

    /**
     * Create an instance of {@link GetAllStations }
     * 
     */
    public GetAllStations createGetAllStations() {
        return new GetAllStations();
    }

    /**
     * Create an instance of {@link GetAllStationsResponse }
     * 
     */
    public GetAllStationsResponse createGetAllStationsResponse() {
        return new GetAllStationsResponse();
    }

    /**
     * Create an instance of {@link StationInfo }
     * 
     */
    public StationInfo createStationInfo() {
        return new StationInfo();
    }

    /**
     * Create an instance of {@link VehicleInfo }
     * 
     */
    public VehicleInfo createVehicleInfo() {
        return new VehicleInfo();
    }

}
