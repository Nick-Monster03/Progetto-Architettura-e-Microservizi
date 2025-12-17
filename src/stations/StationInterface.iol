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

interface StationInterface {
    RequestResponse:
        unlock(UnlockRequest)(UnlockResponse),
        lock(LockRequest)(LockResponse)
}