include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../simulation/SimulatorInterface.iol"
include "../../user-management/UserInterface.iol"
from time import Time
from console import Console

service FleetGateway {
    execution: concurrent

    inputPort GatewayPort {
        Location: "socket://0.0.0.0:8082"
        Protocol: http { 
            .format = "json";
            .cors= "true";
            .osc.startTracking.method = "post";
            .osc.registerUser.method = "post";
            .osc.stopTracking.method = "post";
            .osc.loginUser.method = "post";
            .osc.bookVehicle.method = "post";
            .osc.getStatus.method = "get";
            .osc.getMap.method = "get";
            .response.headers.("Access-Control-Allow-Origin") = "*";
            .response.headers.("Access-Control-Allow-Methods") = "POST, GET, OPTIONS";
            .response.headers.("Access-Control-Allow-Headers") = "Content-Type";
            .default = "preflight";
            .osc.preflightRegister.method = "options";
            .osc.preflightRegister.alias = "registerUser";

            .osc.preflightLogin.method = "options";
            .osc.preflightLogin.alias = "loginUser";
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
        Location: "socket://user-service:8005" 
        Protocol: soap 
        Interfaces: UserInterface
    }
   
    init {
        println@Console("Fleet Gateway avviato su porta 8082 (REST)")()
    }

    main {

        [ preflightRegister( request )( response ) {
            println@Console("[GW] CORS Preflight per Register approvato!")()
        } ]

        [ preflightLogin( request )( response ) {
            println@Console("[GW] CORS Preflight per Login approvato!")()
        } ]

        [ registerUser( request )( response ) {
            if ( !is_defined( request.username ) ) {
                response.success = true;
                response.message = "CORS OK"   
            } else {
                println@Console("[GW] Inoltro richiesta di registrazione per: " + request.username)();
                registerUser@UserClient( request )( response )
            }
        } ]

        [ loginUser( request )( response ) {
            if ( !is_defined( request.username ) ) {
                response.success = true;
                response.message = "CORS OK"   
            } else {
                println@Console("[GW] Inoltro richiesta di login per: " + request.username)();
                loginUser@UserClient( request )( response )
            }
        } ]

        [ preflight( request )( response ) {
            println@Console("[GW] Richiesta CORS Preflight intercettata e approvata!")()
        } ]

        [ startTracking( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            println@Console("START del Tracking -> Veicolo: " + vid + ", User: " + uid)();

            // Leggo lo status attuale dal DB tramite TrackingService
            getInfo@TrackingClient( { .vehicleId = vid } )( currentInfo );

            if ( currentInfo.status == "IN_USE" || currentInfo.status == "RESERVED" ) {
                response.success = false;
                response.message = "Veicolo non disponibile (stato: " + currentInfo.status + ")";
                println@Console(" > ERRORE: Veicolo " + vid + " è in stato " + currentInfo.status)()
            } else {
                // Leggo batteria iniziale dal DB tramite BatteryService
                getBattery@BatteryClient( { .vehicleId = vid } )( batInfo );
                println@Console("Dati iniziali per " + vid + ": KM=" + currentInfo.totalKm + ", Bat=" + batInfo.level + "%")();

                // Salvo solo il delta di sessione in memoria (startKm e startBattery)
                synchronized( sessionLock ) {
                    global.active_rentals.(vid).startKm      = currentInfo.totalKm;
                    global.active_rentals.(vid).startBattery = batInfo.level;
                    println@Console(" > Sessione salvata: startKm=" + currentInfo.totalKm + ", startBat=" + batInfo.level)()
                };

                // Aggiorno lo status nel DB tramite TrackingService
                setStatus@TrackingClient( { .vehicleId = vid, .status = "IN_USE" } )( setResp );

                // Avvio simulazione
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

            // Leggo lo status attuale dal DB
            getInfo@TrackingClient( { .vehicleId = vid } )( currentInfo );

            if ( currentInfo.status != "IN_USE" ) {
                response.success = false;
                response.message = "Veicolo non in uso (stato: " + currentInfo.status + ")";
                response.kilometers = 0.0;
                response.batteryConsumed = 0.0;
                response.finalBattery = 0;
                println@Console(" > ERRORE: Veicolo " + vid + " non è IN_USE")()
            } else {
                // Fermo la simulazione e ricevo i dati finali
                sim_request.vehicleId = vid;
                stopSimulation@SimulatorClient( sim_request )( simStopResp );
                println@Console("Simulazione fermata - Dati finali ricevuti")();

                deltaKm  = 0.0;
                deltaBat = 0.0;

                synchronized( sessionLock ) {
                    if ( is_defined( global.active_rentals.(vid) ) ) {
                        startK = global.active_rentals.(vid).startKm;
                        startB = global.active_rentals.(vid).startBattery;

                        deltaKm  = simStopResp.totalKm - startK;
                        deltaBat = double(startB - simStopResp.level);

                        undef( global.active_rentals.(vid) )
                    } else {
                        println@Console("WARN: Nessuna sessione attiva trovata per " + vid)()
                    }
                };

                // Aggiorno lo status nel DB tramite TrackingService
                setStatus@TrackingClient( { .vehicleId = vid, .status = "AVAILABLE" } )( setResp );

                response.success        = true;
                response.message        = "Noleggio terminato";
                response.kilometers     = deltaKm;
                response.batteryConsumed = deltaBat;
                response.finalBattery   = simStopResp.level;

                println@Console(" > Report: KM=" + deltaKm + ", BatCons=" + deltaBat)()
            }
        } ]

        [ getStatus( request )( response ) {
            vid = request.vehicleId;
            
            println@Console("[GW] Chiamo TrackingService...")();
            getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
            println@Console("[GW] Tracking ha risposto!")();

            println@Console("[GW] Chiamo BatteryService...")();
            getBattery@BatteryClient( { .vehicleId = vid } )( batLevel );
            println@Console("[GW] Battery ha risposto: " + batLevel.level + "%")();

            response.vehicleId    = vid;
            response.batteryLevel = batLevel.level;
            response.latitude     = trackInfo.location.latitude;
            response.longitude    = trackInfo.location.longitude;
            response.status       = trackInfo.status;

            println@Console("GetStatus per veicolo " + vid + ": Bat=" + batLevel.level + ", Loc=(" + response.latitude + "," + response.longitude + "), Status=" + response.status)()
        } ]
    }
}

