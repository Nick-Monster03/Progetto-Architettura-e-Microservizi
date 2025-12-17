type CalculateRequest {
    minutes: int
    batteryLevel: int
}
type CalculateResponse {
    totalCost: double
    message: string
}

interface CostCalculatorInterface {
    RequestResponse: calculateCost(CalculateRequest)(CalculateResponse)
}