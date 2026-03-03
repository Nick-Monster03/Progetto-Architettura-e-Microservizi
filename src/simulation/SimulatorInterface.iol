type StartSimulationRequest {
    .vehicleId: string
}

type StopSimulationRequest {
    .vehicleId: string
}

type LocationType {
    .latitude: double
    .longitude: double
}

type StopSimulationResponse {
    .vehicleId: string
    .location: LocationType
    .status: string // AVAILABLE, RENTED, RESERVED
    .totalKm: double
    .level: int
}

interface SimulatorInterface {
    RequestResponse:
        stopSimulation( StopSimulationRequest )( StopSimulationResponse )
    OneWay:
        startSimulation( StartSimulationRequest )
}
