include "CostCalculatorInterface.iol"

service CostCalculator {
    execution: concurrent
    
    inputPort CalculatorPort {
        Location: "local://CostCalculator" 
        Protocol: sodep
        Interfaces: CostCalculatorInterface
    }

    main {
        // Calcola costo basato sui minuti con eventuale penale batteria
        calculateCost( request )( response ) {
            ratePerMinute = 0.25;
            baseCost = request.minutes * ratePerMinute;
            
            // Se la batteria è sotto il 15%, applica penale
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