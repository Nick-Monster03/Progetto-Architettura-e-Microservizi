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
        Location: "socket://0.0.0.0:8083"
        Protocol: soap {
            .wsdl = "./StationService.wsdl";
            .wsdl.port = "StationPortServicePort";
            .dropRootValue = true
        }
        Interfaces: StationInterface
    }

    init {
        // Inizializzazione dati di test (Debug)
        global.station_vehicles.("v-test").locked = true
        global.station_vehicles.("v-test").station = "Stazione-Termini"
        println@Console("Station Service (SOAP) avviato sulla porta 8083")()
    }

    main {

        // Operazione 'unlock': Inizia una sessione di noleggio
        unlock( request )( response ) {
            id = request.vehicleId;
            println@Console( "[UNLOCK-REQ] Veicolo: " + id + " Utente: " + request.userId )();
            
            // Blocco sincronizzato per evitare race condition sullo stato globale dei veicoli
            synchronized( lock ) {
                // Se il veicolo non esiste, lo creiamo in una stazione fittizia
                if ( !is_defined( global.station_vehicles.(id) ) ) {
                     global.station_vehicles.(id).station = "Stazione-Virtuale"
                };
                
                // Imposta lo stato a sbloccato
                global.station_vehicles.(id).locked = false;
                
                // Genera un nuovo ID di sessione (SID) per questo noleggio
                csets.sid = new;
                response.sid = csets.sid;
                
                response.success = true;
                response.message = "Veicolo sbloccato correttamente."
            }
        };

        // Operazione 'lock': Termina la sessione (richiede il SID corretto)
        [lock( request )( response ) {
            undef(response) // Pulizia variabile risposta
            id = request.vehicleId;
            station = request.stationId;
            println@Console( "[LOCK-REQ] Veicolo: " + id + " presso " + station )();
            
            synchronized( lock ) {
                // Blocca il veicolo e aggiorna la sua posizione (stazione)
                global.station_vehicles.(id).locked = true;
                global.station_vehicles.(id).station = station
            };

            response.success = true;
            response.message = "Veicolo bloccato e parcheggiato."
        }] 
    }
}