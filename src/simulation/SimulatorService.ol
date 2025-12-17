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

    main {
        println@Console("--- AVVIO SIMULATORE ---")();
        
        while( true ) {
            getRentedVehicles@Tracking()( rentedList );
            
            for ( i = 0, i < #rentedList.vehicleIds, i++ ) {
                vid = rentedList.vehicleIds[i];
                
                getInfo@Tracking( {.vehicleId = vid} )( info );
                random@Math()( r );
                newLat = info.location.latitude + (r * 0.001);
                newLon = info.location.longitude + (r * 0.001);
                
                updateLocation@Tracking({ 
                    .vehicleId = vid, 
                    .location.latitude = newLat, 
                    .location.longitude = newLon 
                })();

                //DEBUG: Aggiorna Batteria (Scarica 1% alla volta)
                getBattery@Battery({ .vehicleId = vid })( batt );
                if ( batt > 0 ) {
                    newBatt = batt - 1;
                    updateBattery@Battery({ .vehicleId = vid, .level = newBatt })()
                };

                println@Console("[SIM] Aggiornato " + vid + " -> Bat: " + newBatt + "%")()
            };

            sleep@Time( 5000 )() 
        }
    }
}