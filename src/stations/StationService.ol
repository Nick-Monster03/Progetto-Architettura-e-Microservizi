include "StationInterface.iol"
include "console.iol"

service StationService {

    execution: concurrent

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
        // Simulazione dello stato puramente di DEBUG
        global.station_vehicles.("v-test").locked = true
        global.station_vehicles.("v-test").station = "Stazione-Termini"
        println@Console("Station Service (SOAP) avviato sulla porta 8083")()
    }

    main {

        unlock( request )( response ) {
            id = request.vehicleId;
            println@Console( "[UNLOCK-REQ] Veicolo: " + id + " Utente: " + request.userId )();
            
            synchronized( lock ) {
                // Logica simulata: sblocca sempre se il veicolo esiste (o lo crea al volo per test)
                if ( !is_defined( global.station_vehicles.(id) ) ) {
                     global.station_vehicles.(id).station = "Stazione-Virtuale"
                };
                
                global.station_vehicles.(id).locked = false;
                
                csets.sid = new;
                response.sid = csets.sid;
                
                response.success = true;
                response.message = "Veicolo sbloccato correttamente."
            }
        };

        [lock( request )( response ) {
            undef(response)
            id = request.vehicleId;
            station = request.stationId;
            println@Console( "[LOCK-REQ] Veicolo: " + id + " presso " + station )();

            synchronized( lock ) {
                global.station_vehicles.(id).locked = true;
                global.station_vehicles.(id).station = station
            };

            response.success = true;
            response.message = "Veicolo bloccato e parcheggiato."
        }]
    }
}