include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../service-utils/CostCalculatorInterface.iol"
from time import Time
from console import Console

service FleetGateway {
    execution: concurrent

    // --- INTERFACCIA ESTERNA (REST/JSON per il Client) ---
    // Manteniamo la configurazione DevMatte per compatibilità Frontend/Docker
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
            
            // Gestione CORS necessaria per il browser
            .osc.handleOptions.method = "options";
            .default = "handleOptions";
            .response.headers.("Access-Control-Allow-Origin") = "*";
            .response.headers.("Access-Control-Allow-Methods") = "GET, POST, OPTIONS, PUT, DELETE";
            .response.headers.("Access-Control-Allow-Headers") = "Content-Type"
        }
        Interfaces: FleetInterface
    }

    // --- SERVIZI INTERNI (SOAP per Backend SOA) ---
    
    // Tracking Service
    outputPort Tracking {
        // Usa il nome del servizio Docker (da DevMatte) ma protocollo SOAP (da develope/traccia)
        Location: "socket://tracking-service:8084" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: TrackingInterface
    }

    // Battery Service
    outputPort Battery {
        Location: "socket://battery-service:8085" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: BatteryInterface
    }

    // Calculator Service (aggiunto da develope)
    outputPort CalculatorPort {
        // Corretto localhost -> calculator-service per Docker
        Location: "socket://calculator-service:8089" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: CostCalculatorInterface
    }

    embed Console as Console

    main {
        
        // Avvia il monitoraggio
        [ startTracking( request )( response ) {
            // Validazione (DevMatte)
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
                
                // Logica SOA
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
                
                // Salvataggio tempo inizio (develope)
                // Se il client non manda il tempo, usiamo quello attuale (opzionale)
                if ( !is_defined(request.time) ) {
                    request.time = new
                };
                global.starting_times.(request.vehicleId) = request.time;

                response.success = true;
                response.message = "Monitoraggio avviato"
            } else {
                println@Console("[GATEWAY] Errore startTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio."
            }
        } ]

        // Termina il noleggio
        [ stopTracking( request )( response ) {
            // Validazione (DevMatte)
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
                
                // 1. Aggiornamento stato
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
                
                // 2. Recupero dati per calcolo
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                // 3. Calcolo Costo (Logica develope)
                costMsg = "";
                if ( is_defined( global.starting_times.(request.vehicleId) ) ) {
                    start_time = global.starting_times.(request.vehicleId);
                    // Se request.time manca, usa timestamp attuale fittizio o ricevuto
                    if ( !is_defined(request.time) ) request.time = start_time + 600000; // fallback 10 min

                    // Calcolo minuti (ms / 60000)
                    minutes = (request.time - start_time) / 60000;
                    if ( minutes < 1 ) minutes = 1; // Minimo 1 minuto

                    calculateCost@CalculatorPort( { .minutes = minutes, .batteryLevel = batt } )( costResponse );
                    costMsg = " Costo: " + costResponse.totalCost + " EUR"
                };

                response.success = true;
                response.message = "Noleggio terminato. Bat: " + batt + "%." + costMsg
            } else {
                println@Console("[GATEWAY] Errore stopTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio per terminare il noleggio."
            }
        } ]

        // Ottieni stato veicolo
        [ getStatus( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                // Chiamate SOAP
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
                response.batteryLevel = -1 
            }
        } ]

        // Operazioni standard (Mantenute da DevMatte)
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
                    response.message = "Registrazione avvenuta con successo!"
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