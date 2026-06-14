type StartTrackingRequest {
    .vehicleId: string
    .userId: string
}

type StartTrackingResponse {
    .success: bool
    .message: string
}

type StopTrackingRequest {
    .vehicleId: string
    .userId: string
}

type StopTrackingResponse {
    .success: bool
    .message: string
    .kilometers: double      
    .batteryConsumed: double 
    .finalBattery: int
}

type GetStatusRequest {
    .vehicleId: string
}

type GetStatusResponse {
    .vehicleId: string
    .batteryLevel: int
    .latitude: double 
    .longitude: double 
    .status: string 
}


interface FleetInterface {
    RequestResponse:
        startTracking(StartTrackingRequest)(StartTrackingResponse),
        stopTracking(StopTrackingRequest)(StopTrackingResponse),
        getStatus(GetStatusRequest)(GetStatusResponse),
        preflight(undefined)(undefined),
}