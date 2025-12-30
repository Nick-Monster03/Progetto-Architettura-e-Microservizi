include "StationInterface.iol"
include "console.iol"

service StationService {

    // Esecuzione concorrente per servire più client simultaneamente
    execution: concurrent

    // Definizione del Correlation Set per la sessione
    // Collega il SID generato nella risposta di 'unlock' al SID richiesto in 'lock'
    cset {
        sid: UnlockResponse.sid LockRequest.sid
    }

    inputPort StationPort {
        // Usa 0.0.0.0 per Docker (fix DevMatte)
        Location: "socket://0.0.0.0:8083"
        Protocol: soap {
            .wsdl = "./StationService.wsdl";
            .wsdl.port = "StationPortServicePort";
            .dropRootValue = true
        }
        Interfaces: StationInterface
    }

    init {
        println@Console("--- STATION SERVICE AVVIATO (Porta 8083) ---")();
        
        // Logica di inizializzazione da 'develope' (più ricca per i test)
        
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
        global.station_vehicles.("v3").reservedBy = "user_b" 
    }

    main {

        // Operazione 'reserve' (presente solo in develope, fondamentale per la traccia)
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

        // Operazione 'unlock' con logica di business avanzata (develope)
        [ unlock( request )( response ) {
            id = request.vehicleId;
            user = request.userId;
            println@Console( "[UNLOCK] Tentativo sblocco " + id + " utente " + user )();
            
            synchronized( lock ) {
                // Fallback: crea il veicolo se non esiste (utile per test al volo)
                if ( !is_defined( global.station_vehicles.(id) ) ) {
                     global.station_vehicles.(id).locked = true;
                     global.station_vehicles.(id).reserved = false;
                     println@Console( "WARNING: Veicolo creato al volo per test." )()
                };

                canUnlock = false;
                
                // CASO A: Veicolo Prenotato
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
                // CASO B: Noleggio Immediato (Nessuna prenotazione)
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
                    response.sid = ""
                    // message già settato nei rami else sopra
                }
            }
        } ]

        // Operazione 'lock'
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