include "TrackingInterface.iol"
include "console.iol"

service TrackingService {
    execution: concurrent

    inputPort TrackingSocket {
        // Usa 0.0.0.0 per Docker (fix DevMatte)
        Location: "socket://0.0.0.0:8084"
        
        // Usa SOAP per specifica SOA (fix develope/Prof)
        Protocol: soap {
            .wsdl = "./TrackingService.wsdl";
            .wsdl.port = "TrackingServicePort";
            .dropRootValue = true
        }
        Interfaces: TrackingInterface
    }

    init {
        // Inizializza veicoli di test (Bari per coerenza col simulatore)
        global.vehicles.("v-test").lat = 41.1171;
        global.vehicles.("v-test").lon = 16.8719;
        global.vehicles.("v-test").status = "AVAILABLE";

        global.vehicles.("v-01").lat = 41.1222;
        global.vehicles.("v-01").lon = 16.8715;
        global.vehicles.("v-01").status = "AVAILABLE";

        global.vehicles.("v-02").lat = 41.1250;
        global.vehicles.("v-02").lon = 16.8800;
        global.vehicles.("v-02").status = "AVAILABLE"
    }

    main {
        // Aggiorna le coordinate di un veicolo
        [ updateLocation( request )( response ) {
            synchronized( trackingLock ) {
                global.vehicles.(request.vehicleId).lat = request.location.latitude;
                global.vehicles.(request.vehicleId).lon = request.location.longitude
            };
            println@Console("[TRACKING] Update " + request.vehicleId)()
        } ]

        // Imposta lo stato (es. RENTED, AVAILABLE)
        [ setStatus( request )( response ) {
            synchronized( trackingLock ) {
                global.vehicles.(request.vehicleId).status = request.status
            };
            println@Console("[TRACKING] Stato " + request.vehicleId + " -> " + request.status)()
        } ]

        // Recupera info singolo veicolo. Se non esiste, lo inizializza di default
        [ getInfo( request )( response ) {
            synchronized( trackingLock ) {
                // Logica "develope": controlli granulari e coordinate su Bari (default)
                if ( !is_defined(global.vehicles.(request.vehicleId).lat) ) {
                    // Coordinate di default (Bari) se non sono ancora settate
                    global.vehicles.(request.vehicleId).lat = 41.1171;
                    global.vehicles.(request.vehicleId).lon = 16.8719
                };
                
                // Se per caso manca lo stato (es. creato solo con updateLocation), mettiamo AVAILABLE
                if ( !is_defined(global.vehicles.(request.vehicleId).status) ) {
                    global.vehicles.(request.vehicleId).status = "AVAILABLE"
                };

                response.location.latitude = global.vehicles.(request.vehicleId).lat;
                response.location.longitude = global.vehicles.(request.vehicleId).lon;
                response.status = global.vehicles.(request.vehicleId).status
            }
        } ]

        // Restituisce la lista completa di tutti i veicoli gestiti
        [ getVehicleList( request )( response ) {
            synchronized( trackingLock ) {
                // Itera sulla mappa globale dei veicoli e costruisce l'array di risposta
                foreach( vid : global.vehicles ) {
                    i = #response.vehicles; // Indice corrente
                    response.vehicles[i].vehicleId = vid;
                    response.vehicles[i].status = global.vehicles.(vid).status;
                    response.vehicles[i].location.latitude = global.vehicles.(vid).lat;
                    response.vehicles[i].location.longitude = global.vehicles.(vid).lon
                }
            }
        } ]
    }
}