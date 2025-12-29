include "TrackingInterface.iol"
include "console.iol"

service TrackingService {
    execution: concurrent

    inputPort TrackingSocket {
        Location: "socket://0.0.0.0:8084"
        Protocol: sodep
        Interfaces: TrackingInterface
    }

    init {
        // Inizializza un veicolo di test
        global.vehicles.("v-test").lat = 41.1171;
        global.vehicles.("v-test").lon = 16.8719;
        global.vehicles.("v-test").status = "AVAILABLE"
    }

    main {
        // Aggiorna le coordinate di un veicolo
        [ updateLocation( request )( response ) {
            global.vehicles.(request.vehicleId).lat = request.location.latitude;
            global.vehicles.(request.vehicleId).lon = request.location.longitude;
            println@Console("[TRACKING] Update " + request.vehicleId)()
        } ]

        // Imposta lo stato (es. RENTED, AVAILABLE)
        [ setStatus( request )( response ) {
            global.vehicles.(request.vehicleId).status = request.status;
            println@Console("[TRACKING] Stato " + request.vehicleId + " -> " + request.status)()
        } ]

        // Recupera info singolo veicolo. Se non esiste, lo inizializza di default
        [ getInfo( request )( response ) {
            if ( !is_defined(global.vehicles.(request.vehicleId)) ) {
                 global.vehicles.(request.vehicleId).lat = 41.1171;
                 global.vehicles.(request.vehicleId).lon = 16.8719;
                 global.vehicles.(request.vehicleId).status = "AVAILABLE"
            };
            response.location.latitude = global.vehicles.(request.vehicleId).lat;
            response.location.longitude = global.vehicles.(request.vehicleId).lon;
            response.status = global.vehicles.(request.vehicleId).status
        } ]

        // Restituisce la lista completa di tutti i veicoli gestiti
        [ getVehicleList( request )( response ) {
            // Itera sulla mappa globale dei veicoli e costruisce l'array di risposta
            foreach( vid : global.vehicles ) {
                i = #response.vehicles; // Indice corrente
                response.vehicles[i].vehicleId = vid;
                response.vehicles[i].status = global.vehicles.(vid).status;
                response.vehicles[i].location.latitude = global.vehicles.(vid).lat;
                response.vehicles[i].location.longitude = global.vehicles.(vid).lon
            }
        } ]
    }
}