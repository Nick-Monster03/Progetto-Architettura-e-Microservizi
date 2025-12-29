include "console.iol"
include "time.iol"
include "math.iol"
include "../fleet-management/tracking/TrackingInterface.iol"
include "../fleet-management/battery/BatteryInterface.iol"

service SimulatorService {
    
    // Porte per comunicare con i servizi di Tracking e Battery
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

    init {
        // Definizione coordinate delle stazioni fisse per la simulazione del percorso
        global.stations[0].lat = 41.1222;
        global.stations[0].lon = 16.8715; 
        global.stations[1].lat = 41.1171;
        global.stations[1].lon = 16.8719; 
        global.stations[2].lat = 41.1250;
        global.stations[2].lon = 16.8800; 
        
        println@Console("[SIM] Simulatore Avviato su Bari.")()
    }

    main {
        // Loop infinito di simulazione
        while( true ) {
            // 1. Recupera la lista di tutti i veicoli dal servizio Tracking
            getVehicleList@Tracking()( list );
            
            // 2. Itera su ogni veicolo
            for ( i = 0, i < #list.vehicles, i++ ) {
                vid = list.vehicles[i].vehicleId;
                status = list.vehicles[i].status;
                
                // 3. Simula movimento solo se il veicolo è NOLEGGIATO
                if ( status == "RENTED" ) {
                    
                    // A. Assegna una destinazione casuale se non ne ha già una
                    if ( !is_defined( global.sim_state.(vid).dest_lat ) ) {
                        random@Math()( r );
                        dest_idx = int(r * 3); // Sceglie a caso tra 0, 1 e 2
                        global.sim_state.(vid).dest_lat = global.stations[dest_idx].lat;
                        global.sim_state.(vid).dest_lon = global.stations[dest_idx].lon;
                        println@Console("[SIM] " + vid + " viaggia verso Stazione " + dest_idx)()
                    };

                    // B. Calcolo vettoriale per spostamento lineare verso la destinazione
                    cur_lat = list.vehicles[i].location.latitude;
                    cur_lon = list.vehicles[i].location.longitude;
                    dest_lat = global.sim_state.(vid).dest_lat;
                    dest_lon = global.sim_state.(vid).dest_lon;

                    delta_lat = dest_lat - cur_lat;
                    delta_lon = dest_lon - cur_lon;
                    
                    // Calcolo nuova posizione (avanzamento del 10% della distanza rimanente)
                    newLat = cur_lat + (delta_lat * 0.1);
                    newLon = cur_lon + (delta_lon * 0.1);

                    // C. Invia aggiornamento posizione al servizio Tracking
                    updateLocation@Tracking({ 
                        .vehicleId = vid, 
                        .location.latitude = newLat, 
                        .location.longitude = newLon 
                    })();

                    // D. Simula consumo batteria (decremento 1%)
                    getBattery@Battery({ .vehicleId = vid })( batt );
                    if ( batt > 0 ) {
                        newBatt = batt - 1;
                        updateBattery@Battery({ .vehicleId = vid, .level = newBatt })()
                    };

                    // E. Controllo arrivo a destinazione (se vicino, resetta destinazione)
                    abs@Math( delta_lat )( abs_lat );
                    abs@Math( delta_lon )( abs_lon );
                    
                    if ( abs_lat < 0.0001 && abs_lon < 0.0001 ) {
                        println@Console("[SIM] " + vid + " ARRIVATO! Cambio destinazione.")();
                        undef( global.sim_state.(vid) ) // Rimuove stato per scegliere nuova meta al prossimo giro
                    } else {
                        println@Console("[SIM] " + vid + " moving... Bat: " + newBatt + "%")()
                    }
                }
            };
            // Pausa tra ogni ciclo di simulazione
            sleep@Time( 3000 )() 
        }
    }
}