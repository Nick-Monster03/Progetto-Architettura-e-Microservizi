include "console.iol"
include "time.iol"
include "math.iol"
// Importa le interfacce per chiamare i servizi
include "../fleet-management/tracking/TrackingInterface.iol"
include "../fleet-management/battery/BatteryInterface.iol"

service SimulatorService {
    
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
        // Stazione A (es. Ateneo)
        global.stations[0].lat = 41.1222; 
        global.stations[0].lon = 16.8715; 
        // Stazione B (es. Stazione Centrale)
        global.stations[1].lat = 41.1171; 
        global.stations[1].lon = 16.8719; 
        // Stazione C (es. Lungomare)
        global.stations[2].lat = 41.1250; 
        global.stations[2].lon = 16.8800; 
        
        println@Console("[SIM] Simulatore Avviato su Bari.")()
    }

    main {
        while( true ) {
            // 1. Chiede la lista completa (API CORRETTA)
            getVehicleList@Tracking()( list );
            
            // 2. Itera sui veicoli
            for ( i = 0, i < #list.vehicles, i++ ) {
                vid = list.vehicles[i].vehicleId;
                status = list.vehicles[i].status;
                
                // 3. Muove solo se RENTED
                if ( status == "RENTED" ) {
                    
                    // A. Assegna Destinazione se non c'è
                    if ( !is_defined( global.sim_state.(vid).dest_lat ) ) {
                        random@Math()( r ); 
                        dest_idx = int(r * 3); // Sceglie staz 0, 1 o 2
                        global.sim_state.(vid).dest_lat = global.stations[dest_idx].lat;
                        global.sim_state.(vid).dest_lon = global.stations[dest_idx].lon;
                        println@Console("[SIM] " + vid + " viaggia verso Stazione " + dest_idx)()
                    };

                    // B. Calcola Movimento Lineare
                    cur_lat = list.vehicles[i].location.latitude;
                    cur_lon = list.vehicles[i].location.longitude;
                    dest_lat = global.sim_state.(vid).dest_lat;
                    dest_lon = global.sim_state.(vid).dest_lon;

                    // Vettore direzione
                    delta_lat = dest_lat - cur_lat;
                    delta_lon = dest_lon - cur_lon;
                    
                    // Step di avanzamento (velocità)
                    step = 0.0005; 
                    
                    // Nuova posizione
                    newLat = cur_lat + (delta_lat * 0.1); // Spostamento del 10% del delta residuo
                    newLon = cur_lon + (delta_lon * 0.1);
                    
                    // C. Invia aggiornamento al Tracking
                    updateLocation@Tracking({ 
                        .vehicleId = vid, 
                        .location.latitude = newLat, 
                        .location.longitude = newLon 
                    })();

                    // D. Aggiorna Batteria
                    getBattery@Battery({ .vehicleId = vid })( batt );
                    if ( batt > 0 ) {
                        newBatt = batt - 1;
                        updateBattery@Battery({ .vehicleId = vid, .level = newBatt })()
                    };

                    // E. Controllo Arrivo (Reset destinazione se vicino)
                    abs@Math( delta_lat )( abs_lat );
                    abs@Math( delta_lon )( abs_lon );
                    
                    if ( abs_lat < 0.0001 && abs_lon < 0.0001 ) {
                        println@Console("[SIM] " + vid + " ARRIVATO! Cambio destinazione.")();
                        undef( global.sim_state.(vid) ) 
                    } else {
                        println@Console("[SIM] " + vid + " moving... Bat: " + newBatt + "%")()
                    }
                }
            };

            sleep@Time( 3000 )() 
        }
    }
}