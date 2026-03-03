type CalculateRequest {
    minutes: long
    batteryLevel: int
}
type CalculateResponse {
    totalCost: double
    message: string
}

interface CostCalculatorInterface {
    RequestResponse: calculateCost(CalculateRequest)(CalculateResponse)
}