include "TrackingInterface.iol"
include "console.iol"
include "database.iol"

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
    with (connectionInfo) {
        .username = "camunda";
        .password = "camunda";
        .port = 5432;          // porta interna Docker
        .host = "postgres";    // nome servizio nel docker-compose 
        .database = "camunda"; // il DB 
        .driver = "postgresql"
    };
    connect@Database(connectionInfo)();
    println@Console("Tracking Service avviato (SOAP port 8084)")();
    println@Console("Connected to camunda")()
}

    main {

        [ updateLocation(request)() {
            synchronized(trackingLock) {
                vid = request.vehicleId;
                newLat = double(request.location.latitude);
                newLon = double(request.location.longitude);

                // Leggi posizione precedente da tracking_veichle
                query@Database(
                    "SELECT latitude, longitude FROM tracking_veichle " +
                    "WHERE vehicle_id = '" + vid + "' ORDER BY id DESC LIMIT 1"
                )(posRes);

                if (#posRes.row == 0) {
                    // Veicolo non ancora in tracking → inserisci primo record
                    update@Database(
                        "INSERT INTO tracking_veichle (vehicle_id, latitude, longitude) " +
                        "VALUES ('" + vid + "', " + newLat + ", " + newLon + ")"
                    )(ir);

                    println@Console("Ricevuto updateLocation per " + vid)();
                    println@Console(" > " + vid + " primo inserimento tracking")()

                } else {
                    oldLat = double(posRes.row[0].latitude);
                    oldLon = double(posRes.row[0].longitude);

                    // Calcolo distanza (approssimazione euclidea)
                    dLat = newLat - oldLat;
                    dLon = newLon - oldLon;
                    if (dLat < 0.0) { dLat = dLat * -1.0 };
                    if (dLon < 0.0) { dLon = dLon * -1.0 };
                    distKm = (dLat + dLon) * 111.0;

                    // Inserisci nuova posizione in tracking_veichle
                    update@Database(
                        "INSERT INTO tracking_veichle (vehicle_id, latitude, longitude) " +
                        "VALUES ('" + vid + "', " + newLat + ", " + newLon + ")"
                    )(ir);

                    // Aggiorna total_km in vehicles
                    query@Database(
                        "SELECT total_km FROM vehicles WHERE vehicle_id = '" + vid + "'"
                    )(kmRes);

                    if (#kmRes.row == 1) {
                        currentKm = double(kmRes.row[0].total_km);
                        newKm = currentKm + distKm;
                        update@Database(
                            "UPDATE vehicles SET total_km = " + newKm + ", last_updated = CURRENT_TIMESTAMP " +
                            "WHERE vehicle_id = '" + vid + "'"
                        )(ur)
                    };

                    println@Console("Ricevuto updateLocation per " + vid)();
                    println@Console("Aggiornamento posizione per " + vid + ": (" + newLat + ", " + newLon + ")")();
                    println@Console(" > " + vid + " moved. New pos: (" + newLat + ", " + newLon + ")")()
                }
            }
        } ]

        [ getInfo(request)(response) {
            vid = request.vehicleId;
            synchronized(trackingLock) {

                // Leggi status e total_km da vehicles
                query@Database(
                    "SELECT status, total_km FROM vehicles WHERE vehicle_id = '" + vid + "'"
                )(vRes);

                // Leggi ultima posizione da tracking_veichle
                query@Database(
                    "SELECT latitude, longitude FROM tracking_veichle " +
                    "WHERE vehicle_id = '" + vid + "' ORDER BY id DESC LIMIT 1"
                )(posRes);

                if (#vRes.row == 0) {
                    println@Console("Richiesta getInfo per veicolo sconosciuto: " + vid)();
                    response.vehicleId           = vid;
                    response.status              = "UNKNOWN";
                    response.totalKm             = 0.0;
                    response.location.latitude   = 0.0;
                    response.location.longitude  = 0.0
                } else {
                    response.vehicleId  = vid;
                    response.status     = vRes.row[0].status;
                    response.totalKm    = double(vRes.row[0].total_km);

                    if (#posRes.row == 1) {
                        response.location.latitude  = double(posRes.row[0].latitude);
                        response.location.longitude = double(posRes.row[0].longitude)
                    } else {
                        response.location.latitude  = 0.0;
                        response.location.longitude = 0.0
                    }
                }
            }
        } ]

        [ setStatus(request)(response) {
            synchronized(trackingLock) {
                update@Database(
                    "UPDATE vehicles SET status = '" + request.status + "', last_updated = CURRENT_TIMESTAMP " +
                    "WHERE vehicle_id = '" + request.vehicleId + "'"
                )(ur);
                println@Console("setStatus: " + request.vehicleId + " → " + request.status)()
            }
        } ]

        [ getVehicleList(request)(response) {
            synchronized(trackingLock) {

                // Leggi tutti i veicoli
                query@Database(
                    "SELECT v.vehicle_id, v.status, v.total_km, " +
                    "t.latitude, t.longitude " +
                    "FROM vehicles v " +
                    "LEFT JOIN tracking_veichle t ON v.vehicle_id = t.vehicle_id " +
                    "AND t.id = (SELECT MAX(id) FROM tracking_veichle WHERE vehicle_id = v.vehicle_id)"
                )(vRes);

                for (i = 0, i < #vRes.row, i++) {
                    row -> vRes.row[i];
                    response.vehicles[i].vehicleId          = row.vehicle_id;
                    response.vehicles[i].status             = row.status;
                    response.vehicles[i].totalKm            = double(row.total_km);

                    if (is_defined(row.latitude)) {
                        response.vehicles[i].location.latitude  = double(row.latitude);
                        response.vehicles[i].location.longitude = double(row.longitude)
                    } else {
                        response.vehicles[i].location.latitude  = 0.0;
                        response.vehicles[i].location.longitude = 0.0
                    }
                }
            }
        } ]
    }
}
