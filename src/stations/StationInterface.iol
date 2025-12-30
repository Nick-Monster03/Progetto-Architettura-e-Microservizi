type UnlockRequest {
    vehicleId: string
    userId: string
}

type UnlockResponse {
    success: bool
    message: string
    sid: string
}

type LockRequest {
    vehicleId: string
    stationId: string
    sid: string
}

type LockResponse {
    success: bool
    message: string
}

type ReserveRequest {
    vehicleId: string
    userId: string
}

type ReserveResponse {
    success: bool
    message: string
}

type StationFaultType {
    stationId: string
    reason: string
}

interface StationInterface {
    RequestResponse:
        unlock(UnlockRequest)(UnlockResponse) throws StationHardwareFault( StationFaultType ),
        lock(LockRequest)(LockResponse),
        reserve(ReserveRequest)(ReserveResponse)
}