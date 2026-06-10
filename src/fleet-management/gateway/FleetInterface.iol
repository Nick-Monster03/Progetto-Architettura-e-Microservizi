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

type UserRequestGw {
    .username?: string
    .password?: string
}

type UserResponseGw {
    .success: bool
    .message: string
}

interface FleetInterface {
    RequestResponse:
        startTracking(StartTrackingRequest)(StartTrackingResponse),
        stopTracking(StopTrackingRequest)(StopTrackingResponse),
        getStatus(GetStatusRequest)(GetStatusResponse),
        registerUser(UserRequestGw)(UserResponseGw),
        loginUser(UserRequestGw)(UserResponseGw),
        preflight(undefined)(undefined),
        preflightRegister(undefined)(undefined),
        preflightLogin(undefined)(undefined)
}