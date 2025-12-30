include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../service-utils/CostCalculatorInterface.iol"
from time import Time


include "console.iol"

service FleetGateway {
    execution: concurrent
    
    inputPort FleetPublicPort {
        Location: "socket://localhost:8082"
        Protocol: http { 
            .format = "json";
            .osc.startTracking.method = "post";
            .osc.stopTracking.method = "post";
            .osc.getStatus.method = "get"
        }
        Interfaces: FleetInterface
    }

    outputPort Tracking {
        Location: "socket://localhost:8084" 
        Protocol: soap
        Interfaces: TrackingInterface
    }

    outputPort Battery {
        Location: "socket://localhost:8085" 
        Protocol: soap
        Interfaces: BatteryInterface
    }

    outputPort CalculatorPort {
        Location: "socket://localhost:8089" 
        Protocol: soap
        Interfaces: CostCalculatorInterface
    }


    main {
        [ startTracking( request )( response ) {
            println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
            
            setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
            
            response.success = true;
            response.message = "Monitoraggio avviato";
            vehicleId = request.vehicleId;
            global.starting_times.vehicleId = request.time
        } ]

        [ stopTracking( request )( response ) {
            println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
            
            setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
            
            getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
            getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

            battery = batt;
            time = request.time; // timestamp in millisecondi del tempo in cui il tracciamento è stato avviato
            vehicleId = request.vehicleId;
            start_time = global.starting_times.vehicleId;

            calculateCost@CalculatorPort( { .minutes = (time - start_time) / 60000, .batteryLevel = batt } )( cost );

            response.success = true;
            response.message = "Noleggio terminato. Bat: " + batt + "%, \n Costo: " + cost.totalCost
        } ]

        [ getStatus( request )( response ) {
            // Aggrega dati da Tracking e Battery
            getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
            getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

            response.vehicleId = request.vehicleId;
            response.status = info.status;
            response.latitude = info.location.latitude;
            response.longitude = info.location.longitude;
            response.batteryLevel = batt
        } ]
    }
}