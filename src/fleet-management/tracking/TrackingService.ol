include "TrackingInterface.iol"
include "console.iol"

service TrackingService {
    execution: concurrent

    inputPort TrackingSocket {
        Location: "socket://0.0.0.0:8084"
        Protocol: soap {
            .wsdl = "./TrackingService.wsdl";
            .wsdl.port = "TrackingServicePort";
            .dropRootValue = true
        }
        Interfaces: TrackingInterface
    }

    init {
        global.vehicles.("car1").lat = 41.1171;
        global.vehicles.("car1").lon = 16.8719;
        global.vehicles.("car1").status = "AVAILABLE";
        global.vehicles.("car1").totalKm = 0.0;

        global.vehicles.("car2").lat = 41.1222;
        global.vehicles.("car2").lon = 16.8715;
        global.vehicles.("car2").status = "AVAILABLE";
        global.vehicles.("car2").totalKm = 0.0;

        global.vehicles.("car3").lat = 41.1200;
        global.vehicles.("car3").lon = 16.8700;
        global.vehicles.("car3").status = "AVAILABLE";
        global.vehicles.("car3").totalKm = 0.0;

        println@Console("Tracking Service avviato (SOAP port 8084)")()
    }

    main {
        [ updateLocation( request )() {
            synchronized( trackingLock ) {
                vid = request.vehicleId;
                
                if ( is_defined( global.vehicles.(vid) ) ) {
                    // 1. Recupero posizione precedente
                    oldLat = global.vehicles.(vid).lat;
                    oldLon = global.vehicles.(vid).lon;
                    
                    // 2. Aggiorno con nuova posizione
                    println@Console("Ricevuto updateLocation per " + vid )();
                    println@Console("Aggiornamento posizione per " + vid + ": (" + request.location.latitude + ", " + request.location.longitude + ")")();
                    newLat = request.location.latitude;
                    newLon = request.location.longitude;
                    global.vehicles.(vid).lat = newLat;
                    global.vehicles.(vid).lon = newLon;

                    // 3. Calcolo Distanza (Euclidea approssimata x 111km per convertire gradi in km)
                    // Delta Lat/Lon
                    dLat = newLat - oldLat;
                    dLon = newLon - oldLon;
                    
                    // Valore Assoluto Manuale (se negativo, moltiplico per -1)
                    if ( dLat < 0.0 ) { dLat = dLat * -1.0 };
                    if ( dLon < 0.0 ) { dLon = dLon * -1.0 };
                    
                    // Somma semplice dei cateti (Approssimazione sufficiente per la demo)
                    // Invece di Pitagora (sqrt), sommiamo gli spostamenti asse X e Y
                    distDeg = dLat + dLon;
                    
                    // Conversione in KM (1 grado ~= 111km)
                    distKm = distDeg * 111.0;
                    // 4. Aggiorno contatore totale
                    global.vehicles.(vid).totalKm = global.vehicles.(vid).totalKm + distKm;

                    println@Console(" > " + vid + " moved. Tot KM: " + global.vehicles.(vid).totalKm )()
                } else {
                    global.vehicles.(vid).lat = request.location.latitude;
                    global.vehicles.(vid).lon = request.location.longitude;
                    global.vehicles.(vid).totalKm = 0.0;
                    global.vehicles.(vid).status = "AVAILABLE"
                }
            }
        } ]

        [ getInfo( request )( response ) {
            vid = request.vehicleId;
            synchronized( trackingLock ) {
                if ( is_defined( global.vehicles.(vid) ) ) {
                    response.vehicleId = vid;
                    response.location.latitude = global.vehicles.(vid).lat;
                    response.location.longitude = global.vehicles.(vid).lon;
                    response.status = global.vehicles.(vid).status;
                    response.totalKm = global.vehicles.(vid).totalKm
                } else {
                    // Veicolo non trovato
                    println@Console("Richiesta getInfo per veicolo sconosciuto1: " + vid)();
                    response.vehicleId = vid;
                    response.status = "UNKNOWN";
                    response.totalKm = 0.0;
                    response.location.latitude = 0.0;
                    response.location.longitude = 0.0
                }
            }
        } ]

        [ setStatus( request )( response ) {
            synchronized( trackingLock ) {
                if ( is_defined( global.vehicles.(request.vehicleId) ) ) {
                    global.vehicles.(request.vehicleId).status = request.status
                }
            }
        } ]

        [ getVehicleList( request )( response ) {
             synchronized( trackingLock ) {
                foreach( vid : global.vehicles ) {
                    i = #response.vehicles;
                    response.vehicles[i].vehicleId = vid;
                    response.vehicles[i].status = global.vehicles.(vid).status;
                    response.vehicles[i].totalKm = global.vehicles.(vid).totalKm;
                    response.vehicles[i].location.latitude = global.vehicles.(vid).lat;
                    response.vehicles[i].location.longitude = global.vehicles.(vid).lon
                }
            }
        } ]
    }
}