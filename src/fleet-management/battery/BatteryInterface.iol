type UpdateBatteryRequest {
    .vehicleId: string
    .level: int
}

type GetBatteryRequest {
    .vehicleId: string
}

type GetBatteryResponse {
    .level: int
}

interface BatteryInterface {
    RequestResponse:
        updateBattery(UpdateBatteryRequest)(void),
        getBattery(GetBatteryRequest)(GetBatteryResponse)
}