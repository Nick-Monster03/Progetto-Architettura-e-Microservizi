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

            if(vid == "" ){
                with( error ) { 
                    .message = "Parametri non validi: vehicleId mancante";
                    .field = "vehicleId"
                };
                throw( InvalidRequestFault, error )
            } else if(uid == ""){
                with( error ) { 
                    .message = "Parametri non validi: userId mancante";
                    .field = "userId"
                };
                throw( InvalidRequestFault, error )
            } else if(sid == ""){
                with( error ) { 
                    .message = "Parametri non validi: stationId mancante";
                    .field = "stationId"
                };
                throw( InvalidRequestFault, error )
            }



            query@Database("SELECT station_id FROM stations WHERE station_id = '" + request.stationId + "'")(stations);
            if(#stations.row == 0){
                with( error ) { 
                    .message = "Station ID non valido";
                    .stationId = request.stationId
                };
                throw( StationNotExistsFault, error )
            }
            query@Database("SELECT vehicle_id FROM vehicles WHERE vehicle_id = '" + request.vehicleId + "'")(veicoli);
            if(#veicoli.row == 0){
                with( error ) { 
                    .message = "Vehicle ID " + request.vehicleId + " non valido"
                };
                throw( VehicleNotFoundFault, error )
            }
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
                else if (res.row[0].status == "CHARGING") {
                    with( error ) {
                        .message = "Veicolo non disponibile, batteria scarica o in ricarica";
                        .currentStatus = res.row[0].status   
                    };
                    throw( VehicleNotAvailableFault, error )
                }
                else if (res.row[0].status == "UNLOCKED" || res.row[0].status == "IN_USE" ) {
                    with( error ) {
                        .message = "Veicolo non disponibile";
                        .currentStatus = res.row[0].status   
                    };
                    throw( VehicleNotAvailableFault, error )
                }
                else if (res.row[0].status == "RESERVED")
                {
                    //prendo tutte le authorization fatte non scadute, quindi ancora valide
                    query@Database(
                    "SELECT * FROM authorizations WHERE vehicle_id = '" + vid + "' 
                    AND user_id = '" + uid + "' AND expires_at > CURRENT_TIMESTAMP ORDER BY created_at desc"
                    )(authRes);

                    if(#authRes.row == 0 ) //non esiste un autorizzazione valida quindi non può prendere quel veicolo
                    {
                        with( error ) {
                        .message = "Veicolo prenotato da un altro utente";
                        .currentStatus = res.row[0].status   
                    };
                    throw( VehicleNotAvailableFault, error )
                    }
                    else {
                        update@Database(
                            "UPDATE vehicles SET status = 'IN_USE', last_updated = CURRENT_TIMESTAMP " +
                            "WHERE vehicle_id = '" + vid + "'"
                        )(ur);

                        response.success = true;
                        response.message = "Veicolo sbloccato correttamente (prenotazione confermata)";
                        println@Console(" > Veicolo " + vid + " SBLOCCATO (da RESERVED, prenotazione di " + uid + ")")()
                    }

                }
                else {
                    update@Database(
                        "UPDATE vehicles SET status = 'IN_USE', last_updated = CURRENT_TIMESTAMP " +
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

            if(vid == ""){
                with( error ) { 
                    .message = "Parametri non validi: vehicleId mancante";
                    .field = "vehicleId"
                };
                throw( InvalidRequestFault, error )
            } else if(uid == ""){
                with( error ) { 
                    .message = "Parametri non validi: userId mancante";
                    .field = "userId"
                };
                throw( InvalidRequestFault, error )
            } else if(sid == ""){
                with( error ) { 
                    .message = "Parametri non validi: stationId mancante";
                    .field = "stationId"
                };
                throw( InvalidRequestFault, error )
            }
            query@Database("SELECT station_id FROM stations WHERE station_id = '" + request.stationId + "'")(stations);
            if(#stations.row == 0){
                with( error ) { 
                    .message = "Station ID non valido";
                    .stationId = request.stationId
                };
                throw( StationNotExistsFault, error )
            }
            query@Database("SELECT vehicle_id FROM vehicles WHERE vehicle_id = '" + request.vehicleId + "'")(veicoli);
            if(#veicoli.row == 0){
                with( error ) { 
                    .message = "Vehicle ID: " + request.vehicleId + " non valido"
                };
                throw( VehicleNotFoundFault, error )
            }

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
                    newStatus = "AVAILABLE";

                    if(res.row[0].battery_level <= 0){
                        newStatus = "CHARGING"
                    }
                    update@Database(
                        "UPDATE vehicles SET status = '" + newStatus + "', last_updated = CURRENT_TIMESTAMP, " +
                        "station_id = '" + sid + "'  " + "WHERE vehicle_id = '" + vid + "'"
                    )(ur);

                    response.success = true;
                    response.message = "Veicolo bloccato";
                    response.finalBatteryLevel = double(res.row[0].battery_level);  // leggo dal DB, non calcolo
                    println@Console(" > Veicolo " + vid + " BLOCCATO (AVAILABLE), batteria: " + response.finalBatteryLevel + "%")()
                }
            }
        } ]

        [ reserve( request )( response ) {
            vid = request.vehicleId;
            sid = request.stationId;
            uid = request.userId;

            query@Database("SELECT station_id FROM stations WHERE station_id = '" + sid + "'")(stations);
            if(#stations.row == 0){
                with( error ) {
                    .message = "Station ID non valido";
                    .stationId = sid
                };
                throw( StationNotExistsFault, error )
            }
            query@Database("SELECT vehicle_id FROM vehicles WHERE vehicle_id = '" + vid + "'")(veicoli);
            if(#veicoli.row == 0){
                with( error ) {
                    .message = "Vehicle ID " + vid + " non valido"
                };
                throw( VehicleNotFoundFault, error )
            }

            println@Console("Richiesta RESERVE per veicolo: " + vid + ", user: " + uid + ", stazione: " + sid)();

            synchronized( lockManager ) {

                query@Database(
                    "SELECT status FROM vehicles WHERE vehicle_id = '" + vid + "'"
                )(res);

                if (#res.row == 0) {
                    with( error ) { .message = "Veicolo " + vid + " non trovato" };
                    throw( VehicleNotFoundFault, error )
                }
                else if (res.row[0].status != "AVAILABLE") {
                    with( error ) {
                        .message = "Veicolo non disponibile per la prenotazione";
                        .currentStatus = res.row[0].status
                    };
                    throw( VehicleNotAvailableFault, error )
                }
                else {
                    update@Database(
                        "UPDATE vehicles SET status = 'RESERVED', last_updated = CURRENT_TIMESTAMP " +
                        "WHERE vehicle_id = '" + vid + "'"
                    )(ur);

                    response.success = true;
                    response.message = "Veicolo prenotato correttamente";
                    println@Console(" > Veicolo " + vid + " RISERVATO per " + uid)()
                }
            }
        } ]

        [ cancelReservation( request )( response ) {
            vid = request.vehicleId;
            sid = request.stationId;

            query@Database("SELECT vehicle_id FROM vehicles WHERE vehicle_id = '" + vid + "'")(veicoli);
            if(#veicoli.row == 0){
                with( error ) {
                    .message = "Vehicle ID " + vid + " non valido"
                };
                throw( VehicleNotFoundFault, error )
            }

            query@Database("SELECT station_id FROM stations WHERE station_id = '" + sid + "'")(stations);
            if(#stations.row == 0){
                with( error ) {
                    .message = "Station ID non valido";
                    .stationId = sid
                };
                throw( StationNotExistsFault, error )
            }

            println@Console("Richiesta CANCEL RESERVATION per veicolo: " + vid + ", stazione: " + sid)();

            synchronized( lockManager ) {

                query@Database(
                    "SELECT status FROM vehicles WHERE vehicle_id = '" + vid + "'"
                )(res);

                if (#res.row == 0) {
                    with( error ) { .message = "Veicolo " + vid + " non trovato" };
                    throw( VehicleNotFoundFault, error )
                }
                else if (res.row[0].status != "RESERVED") {
                    with( error ) {
                        .message = "Il veicolo non è attualmente prenotato";
                        .currentStatus = res.row[0].status
                    };
                    throw( VehicleNotAvailableFault, error )
                }
                else {
                    update@Database(
                        "UPDATE vehicles SET status = 'AVAILABLE', last_updated = CURRENT_TIMESTAMP " +
                        "WHERE vehicle_id = '" + vid + "'"
                    )(ur);

                    response.success = true;
                    response.message = "Prenotazione annullata, veicolo di nuovo disponibile";
                    println@Console(" > Veicolo " + vid + " torna AVAILABLE (prenotazione annullata)")()
                }
            }
        } ]


        [ getAllStations(request)( response ) {
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
                        if (is_defined(row.vehicle_id) && row.vehicle_id != "") {
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

                    if (is_defined(row.vehicle_id) && row.vehicle_id != "") {
                        response.stations[stIdx].vehicles[0].vehicleId = row.vehicle_id;
                        response.stations[stIdx].vehicles[0].status    = row.status;
                        response.stations[stIdx].vehicles[0].battery   = double(row.battery_level)
                    };

                    stIdx++
                }
            };

            println@Console(" > Restituite " + stIdx + " stazioni")()
        } ]

        [getVehicles(request)(response){

            queryStr = "SELECT vehicle_id FROM vehicles";
            hasStation = is_defined(request.stationId);

            if (hasStation) {
                query@Database("SELECT station_id FROM stations WHERE station_id = '" + request.stationId + "'")(stationCheck);
                if (#stationCheck.row == 0) {
                    with( error ) { 
                        .message = "Station ID: " + request.stationId + " non valido"
                    };
                    throw( StationNotExistsFault, error )
                }
            }

            if (hasStation && request.availableOnly == true) {
                queryStr += " WHERE station_id = '" + request.stationId + "' AND status = 'AVAILABLE'"
            } else if (hasStation && request.availableOnly == false) {
                queryStr += " WHERE station_id = '" + request.stationId + "'"
            } else if (!hasStation && request.availableOnly == true) {
                queryStr += " WHERE status = 'AVAILABLE'"
            }

            query@Database(queryStr)(res);
                
            print@Console(" > Veicoli trovati: " + #res.row)();
            // if(#res.row == 0){
            //     with( error ) { 
            //         .message = "Nessun veicolo trovato con i criteri specificati: " + queryStr
            //     };
            //     throw( VehicleNotFoundFault, error )
            // }
            
            for (i = 0, i < #res.row, i++) {
                response.vehicles[i] = res.row[i].vehicle_id
            }

        }]

        [getStationByVehicleId(request)(response){
            vid = request.vehicleId;
            println@Console("Richiesta getStationByVehicle per veicolo: " + vid)();

            query@Database(
                "SELECT s.station_id, s.name, s.latitude, s.longitude " +
                "FROM stations s " +
                "JOIN vehicles v ON s.station_id = v.station_id " +
                "WHERE v.vehicle_id = '" + vid + "'"
            )(res);

            if (#res.row == 0) {
                with( error ) { .message = "Veicolo " + vid + " non trovato" };
                throw( VehicleNotFoundFault, error )
            }
            else {
                response.stationId = res.row[0].station_id;
                println@Console(" > Veicolo " + vid + " si trova alla stazione: " + response.stationId)()
            }
        }]

    }
}
