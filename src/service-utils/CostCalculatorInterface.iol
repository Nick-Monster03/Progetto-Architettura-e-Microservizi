type CalculatePriceRequest {
    .durationMinutes: double
    .kilometers: double
    .finalBatteryLevel: int  
    .needsPenaltyTime: bool //indica se bisogna applicare il penalty de ritiro in ritardo
}


type PriceBreakdown {
    .basePriceTime: double      
    .basePriceDistance: double  
    .subtotal: double           // basePriceTime + basePriceDistance
    .penalty: double           
    .total: double                       
}

interface CostCalculatorInterface {
    RequestResponse: calculateCost(CalculatePriceRequest)(PriceBreakdown)
}