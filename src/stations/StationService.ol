include "console.iol"
include "StationInterface.iol"

service StationService {   
    
    execution: concurrent 

    inputPort StationPort {
        Location: "socket://0.0.0.0:8083"
        Protocol: soap
        Interfaces: StationInterface
    }

    /* STATO DEI VEICOLI (Simulato) */
    init {
        // Inizializzazione stazioni con veicoli (corrispondenti al Fleet)
        
        // Stazione 1
        global.stations.station1.stationId = "station1";
        global.stations.station1.vehicles.car1.vehicleId = "car1";
        global.stations.station1.vehicles.car1.status = "AVAILABLE";
        global.stations.station1.vehicles.car1.battery = 76.0;
        
        // Stazione 2
        global.stations.station2.stationId = "station2";
        global.stations.station2.vehicles.car2.vehicleId = "car2";
        global.stations.station2.vehicles.car2.status = "AVAILABLE";
        global.stations.station2.vehicles.car2.battery = 80.0;
        
        // Stazione 3
        global.stations.station3.stationId = "station3";
        global.stations.station3.vehicles.car3.vehicleId = "car3";
        global.stations.station3.vehicles.car3.status = "AVAILABLE";
        global.stations.station3.vehicles.car3.battery = 100.0;
        
        // Manteniamo anche global.vehicles per compatibilità con unlock/lock esistenti
        global.vehicles.car1 << global.stations.station1.vehicles.car1;
        global.vehicles.car2 << global.stations.station2.vehicles.car2;
        global.vehicles.car3 << global.stations.station3.vehicles.car3;

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

        // OPERAZIONE GET ALL STATIONS
        [ getAllStations()( response ) {
            println@Console( "Richiesta getAllStations" )()
            
            i = 0;
            foreach( stationId : global.stations ) {
                response.stations[i].stationId = global.stations.(stationId).stationId;
                
                j = 0;
                foreach( vehicleId : global.stations.(stationId).vehicles ) {
                    response.stations[i].vehicles[j].vehicleId = global.stations.(stationId).vehicles.(vehicleId).vehicleId;
                    response.stations[i].vehicles[j].status = global.stations.(stationId).vehicles.(vehicleId).status;
                    response.stations[i].vehicles[j].battery = global.stations.(stationId).vehicles.(vehicleId).battery;
                    j++
                };
                i++
            };
            
            println@Console( " > Restituite " + i + " stazioni" )()
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
}