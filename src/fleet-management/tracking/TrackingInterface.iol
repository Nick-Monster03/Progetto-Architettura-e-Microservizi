type LocationType {
    .latitude: double
    .longitude: double
}

type VehicleInfo {
    .vehicleId: string
    .location: LocationType
    .status: string // AVAILABLE, RENTED, RESERVED
    .totalKm: double
}

type VehicleList {
    .vehicles*: VehicleInfo
}


type UpdateLocationRequest {
    .vehicleId: string
    .location: LocationType
}

type GetInfoRequest {
    .vehicleId: string
}


interface TrackingInterface {
    RequestResponse:
        getInfo( GetInfoRequest )( VehicleInfo ),
        updateLocation( UpdateLocationRequest )( void ),
        getVehicleList( void )( VehicleList )
}