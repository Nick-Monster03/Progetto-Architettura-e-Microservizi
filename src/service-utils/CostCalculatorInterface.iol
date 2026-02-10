type CalculatePriceRequest {
    .durationMinutes: double
    .kilometers: double
    .finalBatteryLevel: int  
}


type PriceBreakdown {
    .basePriceTime: double      
    .basePriceDistance: double  
    .subtotal: double           // basePriceTime + basePriceDistance
    .penalty: double           
    .total: double              
    .needsPenalty: bool         
}

interface CostCalculatorInterface {
    RequestResponse: calculateCost(CalculatePriceRequest)(PriceBreakdown)
}