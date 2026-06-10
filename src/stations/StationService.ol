include "console.iol"
include "database.iol"
include "StationInterface.iol"

service StationService {   
    
    execution: concurrent 

    inputPort StationPort {
        Location: "socket://0.0.0.0:8083"
        Protocol: soap {
            .wsdl = "StationService.wsdl"
        }
        Interfaces: StationInterface
    }

    init {
        with (connectionInfo) {
            .username = "camunda";
            .password = "camunda";
            .host = "postgres";
            .port = 5432;
            .database = "camunda";
            .driver = "postgresql"
        };
        connect@Database(connectionInfo)();
        println@Console("Station Service avviato (Porta 8083)")();
        println@Console("Connected to camunda DB")()
    }

    main {

        [ unlock( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            sid = request.stationId;
            println@Console("Richiesta UNLOCK per veicolo: " + vid + ", user: " + uid + ", stazione: " + sid)();

            synchronized( lockManager ) {

                query@Database(
                    "SELECT status FROM vehicles WHERE vehicle_id = '" + vid + "'"
                )(res);

                if (#res.row == 0) {
                    with( error ) { .message = "Veicolo " + vid + " non trovato" };
                    throw( VehicleNotFoundFault, error )
                }
                else if (res.row[0].status == "BROKEN") {
                    with( error ) {
                        .message = "Errore hardware veicolo " + vid;
                        .vehicleId = vid
                    };
                    throw( HardwareErrorFault, error )
                }
                else if (res.row[0].status == "UNLOCKED" || res.row[0].status == "IN_USE" || res.row[0].status == "RESERVED") {
                    with( error ) {
                        .message = "Veicolo non disponibile";
                        .currentStatus = res.row[0].status   
                    };
                    throw( VehicleNotAvailableFault, error )
                }
                else {
                    update@Database(
                        "UPDATE vehicles SET status = 'UNLOCKED', last_updated = CURRENT_TIMESTAMP " +
                        "WHERE vehicle_id = '" + vid + "'"
                    )(ur);

                    response.success = true;
                    response.message = "Veicolo sbloccato correttamente";
                    println@Console(" > Veicolo " + vid + " SBLOCCATO")()
                }
            }
        } ]

        [ lock( request )( response ) {
            vid = request.vehicleId;
            uid = request.userId;
            sid = request.stationId;
            println@Console("Richiesta LOCK per veicolo: " + vid + ", user: " + uid + ", stazione: " + sid)();

            synchronized( lockManager ) {

                query@Database(
                    "SELECT status, battery_level FROM vehicles WHERE vehicle_id = '" + vid + "'"
                )(res);

                if (#res.row == 0) {
                    with( error ) { .message = "Veicolo " + vid + " non trovato" };
                    throw( VehicleNotFoundFault, error )
                }
                else {
                    update@Database(
                        "UPDATE vehicles SET status = 'AVAILABLE', last_updated = CURRENT_TIMESTAMP " +
                        "WHERE vehicle_id = '" + vid + "'"
                    )(ur);

                    response.success = true;
                    response.message = "Veicolo bloccato";
                    response.finalBatteryLevel = double(res.row[0].battery_level);  // leggo dal DB, non calcolo
                    println@Console(" > Veicolo " + vid + " BLOCCATO (AVAILABLE), batteria: " + response.finalBatteryLevel + "%")()
                }
            }
        } ]

        // OPERAZIONE GET ALL STATIONS (debug)
        [ getAllStations()( response ) {
            println@Console("Richiesta getAllStations")();

            query@Database(
                "SELECT s.station_id, s.name, s.latitude, s.longitude, " +
                "v.vehicle_id, v.status, v.battery_level " +
                "FROM stations s " +
                "LEFT JOIN vehicles v ON s.station_id = v.station_id " +
                "ORDER BY s.station_id, v.vehicle_id"
            )(res);

            stIdx = 0;
            for (i = 0, i < #res.row, i++) {
                row -> res.row[i];
                sid = row.station_id;

                // Cerco se la stazione è già nell'array risposta
                found = false;
                for (k = 0, k < stIdx, k++) {
                    if (response.stations[k].stationId == sid) {
                        found = true;
                        // Aggiungo il veicolo alla stazione esistente
                        vIdx = #response.stations[k].vehicles;
                        if (is_defined(row.vehicle_id)) {
                            response.stations[k].vehicles[vIdx].vehicleId = row.vehicle_id;
                            response.stations[k].vehicles[vIdx].status    = row.status;
                            response.stations[k].vehicles[vIdx].battery   = double(row.battery_level)
                        }
                    }
                };

                if (!found) {
                    // Nuova stazione
                    response.stations[stIdx].stationId = sid;
                    response.stations[stIdx].name      = row.name;
                    response.stations[stIdx].latitude  = double(row.latitude);
                    response.stations[stIdx].longitude = double(row.longitude);

                    if (is_defined(row.vehicle_id)) {
                        response.stations[stIdx].vehicles[0].vehicleId = row.vehicle_id;
                        response.stations[stIdx].vehicles[0].status    = row.status;
                        response.stations[stIdx].vehicles[0].battery   = double(row.battery_level)
                    };

                    stIdx++
                }
            };

            println@Console(" > Restituite " + stIdx + " stazioni")()
        } ]
    }
}
