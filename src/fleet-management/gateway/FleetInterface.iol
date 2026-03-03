type StartTrackingRequest {
    vehicleId: string
    userId: string
    time: long // timestamp in millisecondi
}

type StartTrackingResponse {
    success: bool
    message: string
}

type StopTrackingRequest {
    vehicleId: string
    userId: string
    time: long
    // battery: int 
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

type BookVehicleRequest: void {
    .vehicleId: string
    .userId: string
}

type BookVehicleResponse: void {
    .success: bool
    .message: string
}

type RegisterUserRequest: void {
    .username: string
    .password: string 
}

type RegisterUserResponse: void {
    .success: bool
    .message: string
}

type ClientLocation {
    latitude: double
    longitude: double
}

type ClientVehicleInfo {
    .vehicleId: string
    .location: ClientLocation 
    .status: string
    .batteryLevel?: int 
}

type GetMapResponse {
    vehicles*: ClientVehicleInfo 
}
// ------------------------------------------

interface FleetInterface {
    RequestResponse:
        startTracking(StartTrackingRequest)(StartTrackingResponse),
        stopTracking(StopTrackingRequest)(StopTrackingResponse),
        getStatus(GetStatusRequest)(GetStatusResponse),
        bookVehicle(BookVehicleRequest)(BookVehicleResponse),
        registerUser(RegisterUserRequest)(RegisterUserResponse),
        getMap( void )( GetMapResponse ),
        handleOptions(void)(void)
}