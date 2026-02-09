type UnlockRequest {
    vehicleId: string
    userId: string
}

type UnlockResponse {
    success: bool
    message: string
}

type LockRequest {
    vehicleId: string
    stationId: string
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

interface StationInterface {
    RequestResponse:
        unlock(UnlockRequest)(UnlockResponse) 
            throws HardwareErrorFault(HardwareErrorFaultType) 
                   VehicleNotFoundFault(VehicleNotFoundFaultType) 
                   VehicleNotAvailableFault(VehicleNotAvailableFaultType),
        lock(LockRequest)(LockResponse) 
            throws HardwareErrorFault(HardwareErrorFaultType) 
                   VehicleNotFoundFault(VehicleNotFoundFaultType),
}