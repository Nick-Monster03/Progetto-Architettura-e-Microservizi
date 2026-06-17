type UnlockRequest {
    vehicleId: string
    userId: string
    stationId: string
}

type UnlockResponse {
    success: bool
    message: string
}

type LockRequest {
    vehicleId: string
    stationId: string
    userId: string
}

type LockResponse {
    success: bool
    message: string
    finalBatteryLevel: double
}

type FaultType {
    message: string
}

type VehicleNotFoundFaultType {
    message: string
}

type VehicleNotAvailableFaultType {
    message: string
    currentStatus?: string
}

type HardwareErrorFaultType {
    message: string
    vehicleId?: string
}

type InvalidRequestFaultType {
    message: string
    field?: string
}

type StationNotExistsFaultType {
    message: string
    stationId?: string
}

type VehicleInfo {
    vehicleId: string
    status: string
    battery: double
}

type StationInfo {
    stationId: string
    name: string
    latitude: double
    longitude: double
    vehicles*: VehicleInfo
}

type GetAllStationsRequest {
    stations: string
}

type GetAllStationsResponse {
    stations*: StationInfo
}

type GetVehiclesRequest {
    stationId?: string
    availableOnly: bool
}

type GetAllVehiclesResponse {
    vehicles*: string
}

type GetStationByVehicleIdRequest {
    vehicleId: string
}

type GetStationByVehicleIdResponse {
    stationId: string
}
    
interface StationInterface {
    RequestResponse:
        unlock(UnlockRequest)(UnlockResponse)
            throws HardwareErrorFault(HardwareErrorFaultType)
                   StationNotExistsFault(StationNotExistsFaultType)
                   InvalidRequestFault(InvalidRequestFaultType)
                   VehicleNotFoundFault(VehicleNotFoundFaultType)
                   VehicleNotAvailableFault(VehicleNotAvailableFaultType),
        lock(LockRequest)(LockResponse)
            throws HardwareErrorFault(HardwareErrorFaultType)
                   InvalidRequestFault(InvalidRequestFaultType)
                   StationNotExistsFault(StationNotExistsFaultType)
                   VehicleNotFoundFault(VehicleNotFoundFaultType),
        getAllStations(GetAllStationsRequest)(GetAllStationsResponse),
        getVehicles(GetVehiclesRequest)(GetAllVehiclesResponse)
            throws StationNotExistsFault(StationNotExistsFaultType),
        getStationByVehicleId(GetStationByVehicleIdRequest)(GetStationByVehicleIdResponse)
            throws VehicleNotFoundFault(VehicleNotFoundFaultType)
        
}
