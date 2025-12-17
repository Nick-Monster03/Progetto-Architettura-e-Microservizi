type UpdateBatteryRequest {
    vehicleId: string
    level: int
}

type GetBatteryRequest {
    vehicleId: string
}

interface BatteryInterface {
    RequestResponse:
        updateBattery(UpdateBatteryRequest)(void),
        getBattery(GetBatteryRequest)(int)
}