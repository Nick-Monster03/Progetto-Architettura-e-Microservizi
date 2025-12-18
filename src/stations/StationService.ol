include "StationInterface.iol"
include "console.iol"

service StationService {

    execution: concurrent

    cset {
        sid: UnlockResponse.sid LockRequest.sid
    }

    inputPort StationPort {
        Location: "socket://localhost:8083" 
        Protocol: soap {
            .wsdl = "./StationService.wsdl";
            .wsdl.port = "StationPortServicePort";
            .dropRootValue = true
        }
        Interfaces: StationInterface
    }

    init {
        println@Console("--- STATION SERVICE AVVIATO (Porta 8083) ---")();
        
        // Veicolo 1: Libero a Termini
        global.station_vehicles.("v1").locked = true
        global.station_vehicles.("v1").station = "Termini"
        global.station_vehicles.("v1").reserved = false

        // Veicolo 2: Libero a Tiburtina
        global.station_vehicles.("v2").locked = true
        global.station_vehicles.("v2").station = "Tiburtina"
        global.station_vehicles.("v2").reserved = false

        // Veicolo 3: Già prenotato (per testare fallimenti)
        global.station_vehicles.("v3").locked = true
        global.station_vehicles.("v3").station = "Eur-Fermi"
        global.station_vehicles.("v3").reserved = true
        global.station_vehicles.("v3").reservedBy = "user_b" // Prenotato da un altro
    }

    main {

        [ reserve( request )( response ) {
            id = request.vehicleId;
            user = request.userId;
            println@Console( "[RESERVE] Richiesta per veicolo " + id + " da utente " + user )();

            synchronized( lock ) {
                if ( !is_defined( global.station_vehicles.(id) ) ) {
                    response.success = false;
                    response.message = "Veicolo non esistente"
                } 
                else if ( global.station_vehicles.(id).locked && !global.station_vehicles.(id).reserved ) {
                    global.station_vehicles.(id).reserved = true;
                    global.station_vehicles.(id).reservedBy = user;
                    
                    response.success = true;
                    response.message = "Veicolo prenotato con successo per 30 min."
                } else {
                    response.success = false;
                    response.message = "Veicolo non disponibile (in uso o già prenotato)."
                }
            }
        } ]

        [ unlock( request )( response ) {
            id = request.vehicleId;
            user = request.userId;
            println@Console( "[UNLOCK] Tentativo sblocco " + id + " utente " + user )();
            
            synchronized( lock ) {
                if ( !is_defined( global.station_vehicles.(id) ) ) {
                     // Fallback per test: creiamo veicolo al volo se non esiste
                     global.station_vehicles.(id).locked = true;
                     global.station_vehicles.(id).reserved = false;
                     println@Console( "WARNING: Veicolo creato al volo per test." )()
                };

                canUnlock = false;
                
                //Veicolo Prenotato
                if ( global.station_vehicles.(id).reserved ) {
                    if ( global.station_vehicles.(id).reservedBy == user ) {
                        println@Console( "-> OK: Utente corrisponde alla prenotazione." )();
                        canUnlock = true;
                        // Consumiamo la prenotazione
                        global.station_vehicles.(id).reserved = false;
                        undef( global.station_vehicles.(id).reservedBy )
                    } else {
                        println@Console( "-> ERRORE: Veicolo riservato a un altro utente!" )();
                        canUnlock = false;
                        response.message = "Veicolo riservato ad un altro utente."
                    }
                } 
                //Noleggio Immediato
                else {
                    if ( global.station_vehicles.(id).locked ) {
                        println@Console( "-> OK: Noleggio immediato." )();
                        canUnlock = true
                    } else {
                        println@Console( "-> ERRORE: Veicolo già in uso." )();
                        canUnlock = false;
                        response.message = "Veicolo già in uso."
                    }
                };
                
                if ( canUnlock ) {
                    global.station_vehicles.(id).locked = false;
                    
                    csets.sid = new;
                    response.sid = csets.sid;
                    
                    response.success = true;
                    response.message = "Veicolo sbloccato. Buon viaggio!"
                } else {
                    response.success = false;
                    // message già settato sopra
                    response.sid = ""
                }
            }
        } ]

        [ lock( request )( response ) {
            id = request.vehicleId;
            station = request.stationId;
            println@Console( "[LOCK] Riconsegna veicolo " + id + " a " + station )();

            synchronized( lock ) {
                global.station_vehicles.(id).locked = true;
                global.station_vehicles.(id).station = station;
                global.station_vehicles.(id).reserved = false 
            };

            response.success = true;
            response.message = "Veicolo bloccato e parcheggiato."
        } ]
    }
}