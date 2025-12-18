include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
from console import Console

service FleetGateway {
    execution: concurrent
    
    inputPort FleetPublicPort {
    Location: "socket://localhost:8082"
    Protocol: http { 
        .format = "json";
        .osc.startTracking.method = "post";
        .osc.stopTracking.method = "post";
        .osc.getStatus.method = "get";
        .response.headers.("Access-Control-Allow-Origin") = "*";
        .response.headers.("Access-Control-Allow-Methods") = "GET, POST, OPTIONS";
        .response.headers.("Access-Control-Allow-Headers") = "Content-Type"
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

    embed Console as Console

    main {
        
        // ----------------------------------------------------------------------
        // OPERAZIONE: startTracking
        // Richiede: vehicleId
        // ----------------------------------------------------------------------
        [ startTracking( request )( response ) {
            // VALIDAZIONE: Controllo se vehicleId è presente
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
                
                // Chiamata al microservizio Tracking
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
                
                response.success = true;
                response.message = "Monitoraggio avviato"
            } else {
                // GESTIONE ERRORE: Dati mancanti
                println@Console("[GATEWAY] Errore startTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio."
            }
        } ]

        // ----------------------------------------------------------------------
        // OPERAZIONE: stopTracking
        // Richiede: vehicleId
        // ----------------------------------------------------------------------
        [ stopTracking( request )( response ) {
            // VALIDAZIONE: Controllo se vehicleId è presente
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
                
                // Aggiornamento stato
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
                
                // Recupero info finali per il report
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                response.success = true;
                response.message = "Noleggio terminato. Bat: " + batt + "%"
            } else {
                // GESTIONE ERRORE
                println@Console("[GATEWAY] Errore stopTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio per terminare il noleggio."
            }
        } ]

        // ----------------------------------------------------------------------
        // OPERAZIONE: getStatus
        // Richiede: vehicleId (per interrogare i servizi)
        // ----------------------------------------------------------------------
        [ getStatus( request )( response ) {
            // VALIDAZIONE
            if ( is_defined( request.vehicleId ) ) {
                // Aggrega dati da Tracking e Battery
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                response.vehicleId = request.vehicleId;
                response.status = info.status;
                response.latitude = info.location.latitude;
                response.longitude = info.location.longitude;
                response.batteryLevel = batt
            } else {
                // GESTIONE ERRORE
                // Poiché GetStatusResponse non ha campi 'success' o 'message' standard,
                // restituiamo valori che indicano un errore nel contenuto.
                println@Console("[GATEWAY] Errore getStatus: vehicleId mancante!")();
                
                response.vehicleId = "UNKNOWN";
                response.status = "ERROR_MISSING_ID";
                response.batteryLevel = -1; // Codice convenzionale per errore
                response.latitude = 0.0;
                response.longitude = 0.0
            }
        } ]
    }
}