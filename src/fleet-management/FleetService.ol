include "Fleetinterface.iol"
include "console.iol"
include "math.iol" 

execution { concurrent }

inputPort FleetPublicPort {
    Location: "socket://localhost:8082"
    Protocol: http {
        .format = "json";
        .osc.startTracking.method = "post"; 
        //.osc.startTracking.template = "/startTracking/{vehicleId}/{userId}";
        .osc.stopTracking.method = "post";
        //.osc.stopTracking.template = "/stopTracking/{vehicleId}/{userId}";   
        .osc.getStatus.method = "get";
        //.osc.getStatus.template = "/getStatus/{vehicleId}"
    }
    Interfaces: FleetInterface
}

init {
    
    // Veicolo di test
    global.vehicles.("v-test").status = "AVAILABLE";
    global.vehicles.("v-test").battery = 100;
    global.vehicles.("v-test").latitude = 41.9028; 
    global.vehicles.("v-test").longitude = 12.4964
}

main {

    [ startTracking( request )( response ) {
        id = request.vehicleId;
        println@Console( "[START] Sblocco veicolo: " + id )();

        synchronized( lock ) {
            global.vehicles.(id).status = "RENTED";
            global.vehicles.(id).userId = request.userId;
            
            if ( !is_defined( global.vehicles.(id).battery ) ) {
                global.vehicles.(id).battery = 100;
                global.vehicles.(id).latitude = 41.9028;
                global.vehicles.(id).longitude = 12.4964
            }
        };

        response.success = true;
        response.message = "Monitoraggio ATTIVO."
    } ]

    [ stopTracking( request )( response ) {
        id = request.vehicleId;
        println@Console( "[STOP] Blocco veicolo: " + id )();

        if (is_defined(global.vehicles.(id))) {
            synchronized( lock ) {
                global.vehicles.(id).status = "AVAILABLE";
                // Aggiorniamo la batteria finale se passata nella request, 
                // AZIONE PURAMENTE DI DEBUG
                if (is_defined(request.battery)) {
                    global.vehicles.(id).battery = request.battery
                };
                undef( global.vehicles.(id).userId )
            };

            response.success = true;
            response.message = "Noleggio terminato."
        } else {
            response.success = false;
            response.message = "Veicolo non trovato."
        }
    } ]

    [ getStatus( request )( response ) {
        id = request.vehicleId;
        
        if ( is_defined( global.vehicles.(id) ) ) {
            // SIMULAZIONE MOVIMENTO E CONSUMO, AZIONE PURAMENTE DI DEBUG
            if ( global.vehicles.(id).status == "RENTED" ) {
                synchronized( lock ) {
                    if ( global.vehicles.(id).battery > 5 ) {
                        global.vehicles.(id).battery = global.vehicles.(id).battery - 5
                    };
                    
                    random@Math()( r );
                    global.vehicles.(id).latitude = global.vehicles.(id).latitude + (r * 0.001);
                    global.vehicles.(id).longitude = global.vehicles.(id).longitude + (r * 0.001)
                }
            };

            response.vehicleId = id;
            response.status = global.vehicles.(id).status;
            response.batteryLevel = global.vehicles.(id).battery;
            response.latitude = global.vehicles.(id).latitude;
            response.longitude = global.vehicles.(id).longitude;
            
            println@Console( "[STATUS] " + id + " | Bat: " + response.batteryLevel + "%" )()
        } else {
            response.vehicleId = id;
            response.status = "UNKNOWN";
            response.batteryLevel = -1
        }
    } ]
}