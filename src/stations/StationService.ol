include "console.iol"
include "StationInterface.iol"

execution { concurrent }

inputPort StationPort {
    Location: "socket://0.0.0.0:8083"
    Protocol: soap
    Interfaces: StationInterface
}

/* STATO DEI VEICOLI (Simulato) */
init {
    // Mappa: vehicleId -> status ("LOCKED", "UNLOCKED")
    // Popoliamo 5 stazioni/veicoli come da specifiche
    global.vehicles.("car1").status = "LOCKED";
    global.vehicles.("car1").battery = 100;
    
    global.vehicles.("car2").status = "LOCKED";
    global.vehicles.("car2").battery = 80;

    // Veicolo "guasto" per testare i Fault
    global.vehicles.("car9").status = "BROKEN"; 

    println@Console( "Station Service avviato (Porta 8083)" )()
}

main {
    
    // OPERAZIONE UNLOCK
    [ unlock( request )( response ) {
        vid = request.vehicleId;
        println@Console( "Richiesta UNLOCK per veicolo: " + vid )();

        synchronized( lockManager ) {
            if ( !is_defined( global.vehicles.(vid) ) ) {
                // FAULT: Veicolo non esiste
                with( error ) { .message = "Veicolo " + vid + " non trovato in stazione" };
                throw( VehicleNotFoundFault, error )
            }
            else if ( global.vehicles.(vid).status == "BROKEN" ) {
                // FAULT: Errore Hardware (Simulato)
                with( error ) { .message = "Errore hardware sblocco veicolo " + vid };
                throw( HardwareErrorFault, error )
            }
            else if ( global.vehicles.(vid).status == "UNLOCKED" ) {
                // FAULT: Già in uso
                with( error ) { .message = "Veicolo già sbloccato/in uso" };
                throw( VehicleNotAvailableFault, error )
            }
            else {
                // OK: Sblocco
                global.vehicles.(vid).status = "UNLOCKED";
                response.success = true;
                response.message = "Veicolo sbloccato correttamente";
                println@Console( " > Veicolo " + vid + " SBLOCCATO." )()
            }
        }
    } ]

    // OPERAZIONE LOCK
    [ lock( request )( response ) {
        vid = request.vehicleId;
        println@Console( "Richiesta LOCK per veicolo: " + vid )();

        synchronized( lockManager ) {
            if ( !is_defined( global.vehicles.(vid) ) ) {
                with( error ) { .message = "Veicolo sconosciuto" };
                throw( VehicleNotFoundFault, error )
            }
            else {
                // OK: Blocco
                global.vehicles.(vid).status = "LOCKED";
                
                // Simuliamo consumo batteria casuale (o leggiamo mock)
                // Per ora statico per semplicità, poi collegheremo al Fleet se serve
                finalBat = global.vehicles.(vid).battery - 5; 
                if (finalBat < 0) finalBat = 0;
                global.vehicles.(vid).battery = finalBat;

                response.success = true;
                response.message = "Veicolo bloccato";
                response.finalBatteryLevel = finalBat;
                
                println@Console( " > Veicolo " + vid + " BLOCCATO. Batt: " + finalBat + "%" )()
            }
        }
    } ]
}