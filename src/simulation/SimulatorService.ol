include "console.iol"
include "time.iol"
include "../fleet-management/tracking/TrackingInterface.iol"
include "../fleet-management/battery/BatteryInterface.iol"
include "SimulatorInterface.iol"


service SimulatorService {

    execution: concurrent

    inputPort SimulatorPort {
        Location: "socket://0.0.0.0:8086"
        Protocol: soap { .dropRootValue = true }
        Interfaces: SimulatorInterface
    }

    outputPort TrackingClient {
        Location: "socket://tracking-service:8084"
        Protocol: soap { .dropRootValue = true }
        Interfaces: TrackingInterface
    }

    outputPort BatteryClient {
        Location: "socket://battery-service:8085"
        Protocol: soap { .dropRootValue = true }
        Interfaces: BatteryInterface
    }

    init {
        //DEBUG
        println@Console("=== SIMULATORE TRAFFICO (GPS + BATTERIA) AVVIATO ===")()
        // println@Console("[SIM] In attesa di comando startSimulation...")();
    }

    main {
        [ startSimulation( request )] {
            println@Console("[SIM] Ricevuto comando START per veicolo: " + request.vehicleId)();
            
            synchronized( simLock ) {
                if ( !global.simulationRunning.( request.vehicleId ) ) {
                    global.simulationRunning.( request.vehicleId ) = true
                } 
            };

            if ( global.simulationRunning.( request.vehicleId ) ) {
                // Avvio il ciclo di simulazione
                sleep@Time( 7000 )();
                while( global.simulationRunning.( request.vehicleId ) ) {
                    
                    scope( sim_car ) {
                        install( 
                            default => 
                                println@Console(" [SIM] ERRORE: " + sim_car.default )();
                                if( is_defined( sim_car.default.message ) ) {
                                    println@Console(" [SIM] Dettaglio: " + sim_car.default.message )()
                                }
                        );
                        
                        vid = request.vehicleId;
                        println@Console("[SIM] Simulazione in corso per veicolo: " + vid)();
                        getInfo@TrackingClient( { .vehicleId = vid } )( info );
                        getBattery@BatteryClient( { .vehicleId = vid } )( batResp );
                        println@Console("[SIM] Dati attuali -> KM: " + info.totalKm + ", Bat: " + batResp.level + "%")();
                        
                        newLat = info.location.latitude + 0.001;
                        updateLocationRequest.vehicleId = vid;
                        updateLocationRequest.location.latitude = double( newLat );
                        updateLocationRequest.location.longitude = double( info.location.longitude );
                        updateLocation@TrackingClient( updateLocationRequest )();
                        
                        if ( batResp.level > 0 ) {
                            newBat = batResp.level - 1;
                            
                            batRequest.vehicleId = vid; 
                            batRequest.level = int(newBat);
                            println@Console("[SIM] Aggiorno batteria per " + vid + " a " + int(newBat) + "%")();
                            updateBattery@BatteryClient( batRequest )();
                            sleep@Time( 7000 )() 

                        } else {
                            println@Console(" [SIM] BATTERIA SCARICA - Simulazione terminata")();
                            global.simulationRunning.( request.vehicleId ) = false
                        }
                    }
                
                }
            }
            undef(request)
        } 

        [ stopSimulation( request )( response ) {
            println@Console("[SIM] Ricevuto comando STOP per veicolo: " + request.vehicleId)();
            
            synchronized( simLock ) {
                if ( global.simulationRunning.( request.vehicleId ) ) {
                    global.simulationRunning.( request.vehicleId ) = false;
                    
                    // Recupero i dati finali dal Tracking e Battery Service
                    vid = request.vehicleId;
                    getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
                    getBattery@BatteryClient( { .vehicleId = vid } )( batInfo );
                    
                    // Costruisco la risposta con tutti i dati
                    response.vehicleId = vid;
                    response.location.latitude = trackInfo.location.latitude;
                    response.location.longitude = trackInfo.location.longitude;
                    response.status = trackInfo.status;
                    response.totalKm = trackInfo.totalKm;
                    response.level = batInfo.level;
                    
                    println@Console("[SIM] Dati finali -> KM: " + response.totalKm + ", Bat: " + response.level + "%")()
                } else {
                    // Se non c'è simulazione attiva, restituisco comunque i dati correnti
                    vid = request.vehicleId;
                    getInfo@TrackingClient( { .vehicleId = vid } )( trackInfo );
                    getBattery@BatteryClient( { .vehicleId = vid } )( batInfo );
                    
                    response.vehicleId = vid;
                    response.location.latitude = trackInfo.location.latitude;
                    response.location.longitude = trackInfo.location.longitude;
                    response.status = trackInfo.status;
                    response.totalKm = trackInfo.totalKm;
                    response.level = batInfo.level
                }
            }
        } ]
    }
}