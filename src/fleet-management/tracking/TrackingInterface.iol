type LocationType {
    .latitude: double
    .longitude: double
}

type VehicleInfo {
    .vehicleId: string
    .location: LocationType
    .status: string // AVAILABLE, RENTED, RESERVED
}

type VehicleList {
    .vehicles*: VehicleInfo
}


type UpdateLocationRequest {
    .vehicleId: string
    .location: LocationType
}

type SetStatusRequest {
    .vehicleId: string
    .status: string
}

type GetInfoRequest {
    .vehicleId: string
}


interface TrackingInterface {
    RequestResponse:
        setStatus( SetStatusRequest )( void ),
        getInfo( GetInfoRequest )( VehicleInfo ),
        updateLocation( UpdateLocationRequest )( void ),
        
        getVehicleList( void )( VehicleList )
}