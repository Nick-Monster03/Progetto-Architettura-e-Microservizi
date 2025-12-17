include "CostCalculatorInterface.iol"

service CostCalculator {
    execution: concurrent
    
    inputPort CalculatorPort {
        Location: "local://CostCalculator" 
        Protocol: sodep
        Interfaces: CostCalculatorInterface
    }

    main {
        calculateCost( request )( response ) {
            ratePerMinute = 0.25;
            baseCost = request.minutes * ratePerMinute;
            
            if ( request.batteryLevel < 15 ) {
                penalty = baseCost * 0.10; // 10% penale
                response.totalCost = baseCost + penalty;
                response.message = "Applicata penale del 10% (Batteria scarica)"
            } else {
                response.totalCost = baseCost;
                response.message = "Tariffa standard applicata"
            }
        }
    }
}