include "CostCalculatorInterface.iol"
from console import Console
from math import Math

service CostCalculator {
    execution: concurrent
    
    inputPort CalculatorPort {
        Location: "socket://0.0.0.0:8089" 
        Protocol: soap{
            .wsdl = "CostCalculatorService.wsdl"
        }
        Interfaces: CostCalculatorInterface
    }

    embed Console as Console
    embed Math as Math

    init {
        
        println@Console( "=== Calculator Service Initialization 2.0 ===" )();
        global.rates.timeRatePerMinute = 0.20;      // €0.20/min
        global.rates.distanceRatePerKm = 0.40;      // €0.40/km
        global.rates.batteryThreshold = 15;         // Soglia 15%
        global.rates.penaltyPercentage = 0.10       // Penale 10%
        

    }

    main {
        
        [ calculateCost( request )( response ) {
            
            duration = request.durationMinutes;
            km = request.kilometers;
            battery = request.finalBatteryLevel;
            needsPenaltyTime = request.needsPenaltyTime;
            
            println@Console( "\n[CALCULATOR] === CALCULATE PRICE ===" )();
            println@Console( "[CALCULATOR] Duration: " + duration + " min" )();
            println@Console( "[CALCULATOR] Distance: " + km + " km" )();
            println@Console( "[CALCULATOR] Final Battery: " + battery + "%" )();
            println@Console( "[CALCULATOR] Needs Late Penalty: " + needsPenaltyTime )();
            
            basePriceTime = duration * global.rates.timeRatePerMinute;
            basePriceDistance = km * global.rates.distanceRatePerKm;
            subtotal = basePriceTime + basePriceDistance;
            
            batteryPenalty = 0.0;
            if( battery < global.rates.batteryThreshold ) {
                batteryPenalty = subtotal * global.rates.penaltyPercentage;
                println@Console( "[CALCULATOR]   ⚠️  LOW BATTERY PENALTY: " + battery + "% < 15%" )()
            };
            
            latePenalty = 0.0;
            if( needsPenaltyTime ) {
                latePenalty = 10.0; // Penale fissa di €10 per ritardo inferiore a 25min
                println@Console( "[CALCULATOR]   LATE PICKUP PENALTY: €" + latePenalty )()
            };
            
            totalPenalty = batteryPenalty + latePenalty;
            total = subtotal + totalPenalty;
            
            round@Math( subtotal { .decimals = 2 } )( subtotalRounded );
            round@Math( batteryPenalty { .decimals = 2 } )( batteryPenaltyRounded );
            round@Math( latePenalty { .decimals = 2 } )( latePenaltyRounded );
            round@Math( totalPenalty { .decimals = 2 } )( totalPenaltyRounded );
            round@Math( total { .decimals = 2 } )( totalRounded );
            
            response.basePriceTime = basePriceTime;
            response.basePriceDistance = basePriceDistance;
            response.subtotal = subtotalRounded;
            response.penalty = totalPenaltyRounded;  // Penale TOTALE (batteria + tardiva)
            response.total = totalRounded;
            
            println@Console( "[CALCULATOR] --- BREAKDOWN ---" )();
            println@Console( "[CALCULATOR]   Base Time: €" + basePriceTime )();
            println@Console( "[CALCULATOR]   Base Distance: €" + basePriceDistance )();
            println@Console( "[CALCULATOR]   Subtotal: €" + subtotalRounded )();
            println@Console( "[CALCULATOR]   Battery Penalty: €" + batteryPenaltyRounded )();
            println@Console( "[CALCULATOR]   Late Penalty: €" + latePenaltyRounded )();
            println@Console( "[CALCULATOR]   Total Penalty: €" + totalPenaltyRounded )();
            println@Console( "[CALCULATOR]   FINAL TOTAL: €" + totalRounded )();
            println@Console( "[CALCULATOR] =================" )()
        }]
    }
}