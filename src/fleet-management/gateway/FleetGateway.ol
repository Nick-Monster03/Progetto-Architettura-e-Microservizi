include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../simulation/SimulatorInterface.iol"
include "../../user-managment/UserInterface.iol"
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
            .osc.loginUser.method = "post";
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
    outputPort UserClient {
        // user-service sarà il nome che daremo al container su Docker
        Location: "socket://user-service:8005" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: UserInterface
    }
   
    init {
        // Dati iniziali (Bari)
        global.vehicles.("car1").lat = 41.1171;
        global.vehicles.("car1").lon = 16.8719;
        global.vehicles.("car1").status = "AVAILABLE";
        global.vehicles.("car1").totalKm = 0.0;
        global.vehicles.("car1").battery = 76;

        global.vehicles.("car2").lat = 41.1222;
        global.vehicles.("car2").lon = 16.8715;
        global.vehicles.("car2").status = "AVAILABLE";
        global.vehicles.("car2").totalKm = 0.0;
        global.vehicles.("car2").battery = 80;

        global.vehicles.("car3").lat = 41.1200;
        global.vehicles.("car3").lon = 16.8700;
        global.vehicles.("car3").status = "AVAILABLE";
        global.vehicles.("car3").totalKm = 0.0;
        global.vehicles.("car3").battery = 100;
        println@Console("Fleet Gateway avviato su porta 8082 (REST)")()
    }

    
    main {

        [ registerUser( request )( response ) {
            println@Console("[GW] Inoltro richiesta di registrazione per: " + request.username)()
            registerUser@UserClient( request )( response )
        } ]

        [ loginUser( request )( response ) {
            println@Console("[GW] Inoltro richiesta di login per: " + request.username)()
            loginUser@UserClient( request )( response )
        } ]

        [ startTracking( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            println@Console("START del Tracking -> Veicolo: " + vid + ", User: " + uid)();

            // Controllo se il veicolo è già in noleggio
            if ( is_defined( global.vehicles.(vid).status ) && global.vehicles.(vid).status == "RENTAL" ) {
                response.success = false;
                response.message = "Veicolo già in noleggio";
                println@Console(" > ERRORE: Veicolo " + vid + " è già in stato RENTAL")()
            } else {
                getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
                
                getBattery@BatteryClient( { .vehicleId = vid } )( batInfo );
                println@Console("Dati iniziali per " + vid + ": KM=" + trackInfo.totalKm + ", Bat=" + batInfo.level + "%")();
                synchronized( sessionLock ) {
                    global.active_rentals.(vid).startKm = trackInfo.totalKm;
                    global.active_rentals.(vid).startBattery = batInfo.level;
                    global.vehicles.(vid).status = "RENTAL";
                    println@Console(" > Sessione salvata: startKm=" + trackInfo.totalKm + ", startBat=" + batInfo.level)()
                };

                sim_request.vehicleId = vid;
                startSimulation@SimulatorClient( sim_request );
                println@Console("Simulazione avviata")();

                response.success = true;
                response.message = "Tracking avviato"
            }
        } ]

        [ stopTracking( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            println@Console("STOP Tracking -> Veicolo: " + vid + ", User: " + uid)();

            // Controllo se il veicolo è effettivamente in noleggio
            if ( !is_defined( global.vehicles.(vid).status ) || global.vehicles.(vid).status != "RENTAL" ) {
                response.success = false;
                response.message = "Veicolo non in noleggio";
                response.kilometers = 0.0;
                response.batteryConsumed = 0.0;
                response.finalBattery = 0;
                println@Console(" > ERRORE: Veicolo " + vid + " non è in stato RENTAL")()
            } else {
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
                        
                        undef( global.active_rentals.(vid) );
                        global.vehicles.(vid).status = "AVAILABLE"
                    } else {
                        println@Console("WARN: Nessuna sessione attiva trovata per " + vid)();
                        global.vehicles.(vid).status = "AVAILABLE"
                    }
                };

                response.success = true;
                response.message = "Noleggio terminato";
                response.kilometers = deltaKm;
                response.batteryConsumed = deltaBat;
                response.finalBattery = simStopResp.level;
                
                println@Console(" > Report: KM=" + deltaKm + ", BatCons=" + deltaBat)()
            }
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