include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../simulation/SimulatorInterface.iol"
from time import Time
from console import Console

service FleetGateway {
    execution: concurrent

    inputPort GatewayPort {
        Location: "socket://0.0.0.0:8082"
        Protocol: http { 
            .format = "json";
            .osc.startTracking.method = "post";
            .osc.registerUser.method = "post";
            .osc.stopTracking.method = "post";
            .osc.bookVehicle.method = "post";
            .osc.getStatus.method = "get";
            .osc.getMap.method = "get";
        }
        Interfaces: FleetInterface
    }

    embed Console as Console

    outputPort TrackingClient {
        Location: "socket://tracking-service:8084" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: TrackingInterface
    }

    outputPort BatteryClient {
        Location: "socket://battery-service:8085"
        Protocol: soap { .dropRootValue = true }
        Interfaces: BatteryInterface
    }

    outputPort SimulatorClient {
        Location: "socket://simulator-service:8086" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: SimulatorInterface
    }
   
    init {
    
        println@Console("Fleet Gateway avviato su porta 8082 (REST)")()
    }

    
    main {

        [ startTracking( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            println@Console("START del Tracking -> Veicolo: " + vid + ", User: " + uid)();

            getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
            
            getBattery@BatteryClient( { .vehicleId = vid } )( batInfo );
            
            synchronized( sessionLock ) {
                global.active_rentals.(vid).startKm = trackInfo.totalKm;
                global.active_rentals.(vid).startBattery = batInfo.level;
                println@Console(" > Sessione salvata: startKm=" + trackInfo.totalKm + ", startBat=" + batInfo.level)()
            };

            sim_request.vehicleId = vid;
            startSimulation@SimulatorClient( sim_request );
            println@Console("Simulazione avviata")();

            response.success = true;
            response.message = "Tracking avviato"
        } ]

        [ stopTracking( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            println@Console("STOP Tracking -> Veicolo: " + vid + ", User: " + uid)();

            sim_request.vehicleId = vid;
            stopSimulation@SimulatorClient( sim_request )( simStopResp );
            println@Console("Simulazione fermata - Dati finali ricevuti")()

            deltaKm = 0.0;
            deltaBat = 0.0;

            synchronized( sessionLock ) {
                if ( is_defined( global.active_rentals.(vid) ) ) {
                    startK = global.active_rentals.(vid).startKm;
                    startB = global.active_rentals.(vid).startBattery;

                    deltaKm = simStopResp.totalKm - startK;
                    deltaBat = double(startB - simStopResp.level); 
                    
                    undef( global.active_rentals.(vid) )
                } else {
                    println@Console("WARN: Nessuna sessione attiva trovata per " + vid)()
                }
            };

            response.success = true;
            response.message = "Noleggio terminato";
            response.kilometers = deltaKm;
            response.batteryConsumed = deltaBat;
            response.finalBattery = simStopResp.level;
            
            println@Console(" > Report: KM=" + deltaKm + ", BatCons=" + deltaBat)()
        } ]

        [ getStatus( request )( response ) {
            vid = request.vehicleId;
            
            println@Console("[GW] Chiamo TrackingService...")()
            getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
            println@Console("[GW] Tracking ha risposto!")()
            println@Console("[GW] Chiamo BatteryService...")()
            getBattery@BatteryClient( { .vehicleId = vid } )( batLevel );
            println@Console("[GW] Battery ha risposto: " + batLevel.level + "%")()

            response.vehicleId = vid;
            response.batteryLevel = batLevel.level;
            response.latitude = trackInfo.location.latitude;
            response.longitude = trackInfo.location.longitude;
            response.status = trackInfo.status;
            println@Console("GetStatus per veicolo " + vid + ": Bat=" + batLevel.level + ", Loc=(" + response.latitude + "," + response.longitude + "), Status=" + response.status )()
        } ]

        
    }
}