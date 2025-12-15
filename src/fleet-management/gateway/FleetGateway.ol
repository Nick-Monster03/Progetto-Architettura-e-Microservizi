include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"


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
        Protocol: sodep
        Interfaces: TrackingInterface
    }

    outputPort Battery {
        Location: "socket://localhost:8085" 
        Protocol: sodep
        Interfaces: BatteryInterface
    }


    main {
        [ startTracking( request )( response ) {
            println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
            
            setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
            
            response.success = true;
            response.message = "Monitoraggio avviato"
        } ]

        [ stopTracking( request )( response ) {
            println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
            
            setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
            
            getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
            getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

            response.success = true;
            response.message = "Noleggio terminato. Bat: " + batt + "%"
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