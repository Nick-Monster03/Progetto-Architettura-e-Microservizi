type Location {
    latitude: double
    longitude: double
}

type UpdateLocationRequest {
    vehicleId: string
    location: Location
}

type SetStatusRequest {
    vehicleId: string
    status: string
}

type GetInfoRequest {
    vehicleId: string
}

type GetInfoResponse {
    location: Location
    status: string
}

type GetRentedResponse {
    vehicleIds*: string
}

interface TrackingInterface {
    RequestResponse:
        updateLocation(UpdateLocationRequest)(void),
        setStatus(SetStatusRequest)(void),
        getInfo(GetInfoRequest)(GetInfoResponse),
        getRentedVehicles(void)(GetRentedResponse)
}