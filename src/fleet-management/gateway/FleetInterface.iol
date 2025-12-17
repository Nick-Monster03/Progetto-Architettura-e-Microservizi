type StartTrackingRequest {
    vehicleId: string
    userId: string
    time: int // timestamp in millisecondi
}

type StartTrackingResponse {
    success: bool
    message: string
}

type StopTrackingRequest {
    vehicleId: string
    userId: string
    time: int 
    battery: int 
}

type StopTrackingResponse {
    success: bool
    message: string
}

type GetStatusRequest {
    userId: string
    vehicleId: string
}

type GetStatusResponse {
    vehicleId: string
    batteryLevel: int
    latitude: double 
    longitude: double 
    status: string 
}

interface FleetInterface {
    RequestResponse:
        startTracking(StartTrackingRequest)(StartTrackingResponse),
        stopTracking(StopTrackingRequest)(StopTrackingResponse),
        getStatus(GetStatusRequest)(GetStatusResponse)
}