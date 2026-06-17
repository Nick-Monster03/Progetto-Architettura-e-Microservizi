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

interface StationInterface {
    RequestResponse:
        unlock(UnlockRequest)(UnlockResponse)
            throws HardwareErrorFault(HardwareErrorFaultType)
                   VehicleNotFoundFault(VehicleNotFoundFaultType)
                   VehicleNotAvailableFault(VehicleNotAvailableFaultType),
        lock(LockRequest)(LockResponse)
            throws HardwareErrorFault(HardwareErrorFaultType)
                   VehicleNotFoundFault(VehicleNotFoundFaultType),
        getAllStations(GetAllStationsRequest)(GetAllStationsResponse)
}
