


type StartTrackingRequest {
    vehicleId: string
    userId: string
    time: int //in millisecondi con getCurrentTimeMillis() otteniamo il tempoa attuale 
    //in millisecondi e con getTimeFromMilliSeconds() otteniamo la stringa con la data e l'ora 
}

type StartTrackingResponse {
    success: bool
    message: string
}

type StopTrackingRequest {
    vehicleId: string
    userId: string
    time: int //in millisecondi
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