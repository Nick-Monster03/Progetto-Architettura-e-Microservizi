from console import Console 
include "../tracking/TrackingInterface.iol"

service TrackingServiceMock {
    execution: concurrent

    inputPort TrackingPort {
        Location: "socket://localhost:8084" 
        Protocol: sodep
        Interfaces: TrackingInterface
    }

    embed Console as Console

    main {
        [ setStatus( request )( ) {
            println@Console("[TRACKING] Set status: " + request.status + " for " + request.vehicleId)()
        } ]

        [ getInfo( request )( response ) {
            println@Console("[TRACKING] Richiesta info per: " + request.vehicleId)();
            
            // Dati simulati di base (Roma Centro)
            response.status = "AVAILABLE";
            response.location.latitude = 41.9028;
            response.location.longitude = 12.4964;

            // Logica per spostare i puntini sulla mappa in base all'ID
            if ( request.vehicleId == "v1" ) {
                // Posizione base
                nullProcess
            } else if ( request.vehicleId == "v2" ) {
                // Spostato un po' a Nord
                response.location.latitude = 41.9128
            } else if ( request.vehicleId == "v3" ) {
                // Spostato un po' a Est
                response.location.longitude = 12.5064
            } else if ( request.vehicleId == "v-test" ) {
                // Spostato a Sud-Ovest
                response.location.latitude = 41.8928;
                response.location.longitude = 12.4864
            }
        } ]
    }
}