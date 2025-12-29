include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
from console import Console

service FleetGateway {
    execution: concurrent

    inputPort FleetPublicPort {
        Location: "socket://0.0.0.0:8082"    
        Protocol: http { 
            .format = "json";
            .osc.startTracking.method = "post";
            .osc.registerUser.method = "post";
            .osc.stopTracking.method = "post";
            .osc.bookVehicle.method = "post";
            .osc.getStatus.method = "get";
            .osc.getMap.method = "get";
            
            // --- CONFIGURAZIONE CORS ---
            .osc.handleOptions.method = "options";
            .default = "handleOptions";
            .response.headers.("Access-Control-Allow-Origin") = "*";
            .response.headers.("Access-Control-Allow-Methods") = "GET, POST, OPTIONS, PUT, DELETE";
            .response.headers.("Access-Control-Allow-Headers") = "Content-Type"
        }
        Interfaces: FleetInterface
    }

    outputPort Tracking {
        Location: "socket://tracking-service:8084" 
        Protocol: sodep
        Interfaces: TrackingInterface
    }

    outputPort Battery {
        Location: "socket://battery-service:8085" 
        Protocol: sodep
        Interfaces: BatteryInterface
    }

    embed Console as Console

    main {
        
        [ startTracking( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
                response.success = true;
                response.message = "Monitoraggio avviato"
            } else {
                println@Console("[GATEWAY] Errore startTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio."
            }
        } ]

        [ stopTracking( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                response.success = true;
                response.message = "Noleggio terminato. Bat: " + batt + "%"
            } else {
                println@Console("[GATEWAY] Errore stopTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio per terminare il noleggio."
            }
        } ]

        [ getStatus( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                response.vehicleId = request.vehicleId;
                response.status = info.status;
                response.latitude = info.location.latitude;
                response.longitude = info.location.longitude;
                response.batteryLevel = batt
            } else {
                println@Console("[GATEWAY] Errore getStatus: vehicleId mancante!")();
                response.vehicleId = "UNKNOWN";
                response.status = "ERROR_MISSING_ID";
                response.batteryLevel = -1; 
                response.latitude = 0.0;
                response.longitude = 0.0
            }
        } ]

        [ bookVehicle( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Richiesta Prenotazione: " + request.vehicleId)();
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RESERVED" } )();
                response.success = true;
                response.message = "Veicolo prenotato con successo per 30 minuti."
            } else {
                response.success = false;
                response.message = "Errore: ID Veicolo mancante."
            }
        } ]

        [ registerUser( request )( response ) {
            if ( is_defined( request.username ) && is_defined( request.password ) ) {
                if ( is_defined( global.users.(request.username) ) ) {
                    response.success = false;
                    response.message = "Errore: L'utente " + request.username + " esiste già!"
                } else {
                    global.users.(request.username) = request.password;
                    println@Console("[GATEWAY] Nuovo utente registrato: " + request.username)();
                    
                    response.success = true;
                    response.message = "Registrazione avvenuta con successo! Ora puoi fare il login."
                }
            } else {
                response.success = false;
                response.message = "Dati mancanti (username o password)."
            }
        } ]

        [ getMap( request )( response ) {
            getVehicleList@Tracking()( trackingData );
            response.vehicles -> trackingData.vehicles
        } ]

        [ handleOptions( request )( response ) {
            nullProcess
        } ]
    }
}