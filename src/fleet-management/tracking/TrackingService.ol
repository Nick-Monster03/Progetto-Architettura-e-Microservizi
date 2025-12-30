include "TrackingInterface.iol"
include "console.iol"

service TrackingService {
    execution: concurrent

   
    inputPort TrackingSocket {
        Location: "socket://localhost:8084"
        Protocol: soap
        Interfaces: TrackingInterface
    }

    init {
        // Init v-test a Roma
        global.vehicles.("v-test").lat = 41.9028;
        global.vehicles.("v-test").lon = 12.4964;
        global.vehicles.("v-test").status = "AVAILABLE"
    }

    main {
        [ updateLocation( request )( response ) {
            global.vehicles.(request.vehicleId).lat = request.location.latitude;
            global.vehicles.(request.vehicleId).lon = request.location.longitude
        } ]

        [ setStatus( request )( response ) {
            global.vehicles.(request.vehicleId).status = request.status;
            println@Console("[TRACKING] Stato " + request.vehicleId + " -> " + request.status)()
        } ]

        [ getInfo( request )( response ) {
            if ( !is_defined(global.vehicles.(request.vehicleId).lat) ) {
                 // Coordinate di default (Roma) se non sono ancora settate
                 global.vehicles.(request.vehicleId).lat = 41.9028;
                 global.vehicles.(request.vehicleId).lon = 12.4964
            };
            
            // Se per caso manca lo stato (es. creato solo con updateLocation), mettiamo AVAILABLE
            if ( !is_defined(global.vehicles.(request.vehicleId).status) ) {
                 global.vehicles.(request.vehicleId).status = "AVAILABLE"
            };
            response.location.latitude = global.vehicles.(request.vehicleId).lat;
            response.location.longitude = global.vehicles.(request.vehicleId).lon;
            response.status = global.vehicles.(request.vehicleId).status
            //println@Console("[TRACKING] Stato " + request.vehicleId + " -> " + response.status)()
        } ]

        [ getRentedVehicles( request )( response ) {
            // Scorre tutti i veicoli e trova quelli RENTED
            i = 0;
            foreach( v : global.vehicles ) {
                if ( global.vehicles.(v).status == "RENTED" ) {
                    response.vehicleIds[i] = v;
                    i++
                }
            }
        } ]
    }
}