include "CostCalculatorInterface.iol"
from console import Console
from math import Math

service CostCalculator {
    execution: concurrent
    
    inputPort CalculatorPort {
        Location: "socket://0.0.0.0:8089" 
        Protocol: soap
        Interfaces: CostCalculatorInterface
    }

    embed Console as Console
    embed Math as Math

    init {
        
        //DEBUG
        println@Console( "=== Calculator Service Initialization ===" )();
        global.rates.timeRatePerMinute = 0.20;      // €0.20/min
        global.rates.distanceRatePerKm = 0.40;      // €0.40/km
        global.rates.batteryThreshold = 15;         // Soglia 15%
        global.rates.penaltyPercentage = 0.10       // Penale 10%
        
        //DEBUG
        // println@Console( "Configured Rates:" )();
        // println@Console( "  - Time: €" + global.rates.timeRatePerMinute + "/min" )();
        // println@Console( "  - Distance: €" + global.rates.distanceRatePerKm + "/km" )();
        // println@Console( "  - Battery threshold: " + global.rates.batteryThreshold + "%" )();
        // println@Console( "  - Penalty: " + (global.rates.penaltyPercentage * 100) + "%" )();
        // println@Console( "" )();
        // println@Console( "Calculator Service ready on port 8010 (SOAP)" )();
        // println@Console( "========================================" )()
    }

    main {
        
        [ calculateCost( request )( response ) {
            
            duration = request.durationMinutes;
            km = request.kilometers;
            battery = request.finalBatteryLevel;
            
            println@Console( "\n[CALCULATOR] === CALCULATE PRICE ===" )();
            println@Console( "[CALCULATOR] Duration: " + duration + " min" )();
            println@Console( "[CALCULATOR] Distance: " + km + " km" )();
            println@Console( "[CALCULATOR] Final Battery: " + battery + "%" )();
            
            basePriceTime = duration * global.rates.timeRatePerMinute;
            basePriceDistance = km * global.rates.distanceRatePerKm;
            subtotal = basePriceTime + basePriceDistance;
            needsPenalty = false;
            penalty = 0.0;
            
            if( battery < global.rates.batteryThreshold ) {
                needsPenalty = true;
                penalty = subtotal * global.rates.penaltyPercentage
            };
            
            total = subtotal + penalty;
            
            round@Math( subtotal { .decimals = 2 } )( subtotalRounded );
            round@Math( penalty { .decimals = 2 } )( penaltyRounded );
            round@Math( total { .decimals = 2 } )( totalRounded );
            
            response.basePriceTime = basePriceTime;
            response.basePriceDistance = basePriceDistance;
            response.subtotal = subtotalRounded;
            response.penalty = penaltyRounded;
            response.total = totalRounded;
            response.needsPenalty = needsPenalty;
            
            //DEBUG
            // println@Console( "[CALCULATOR]   Time cost: €" + basePriceTime )();
            // println@Console( "[CALCULATOR]   Distance cost: €" + basePriceDistance )();
            // println@Console( "[CALCULATOR]   Subtotal: €" + subtotalRounded )();
            
            if( needsPenalty ) {
                println@Console( "[CALCULATOR]   ⚠️  LOW BATTERY PENALTY: €" + penaltyRounded + " (" + 
                    (global.rates.penaltyPercentage * 100) + "%)" )()
            };
            
            println@Console( "[CALCULATOR]   TOTAL: €" + totalRounded )()
        }]
    }
}