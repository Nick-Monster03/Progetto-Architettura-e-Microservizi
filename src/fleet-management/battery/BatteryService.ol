include "BatteryInterface.iol"
include "console.iol"
include "database.iol"

service BatteryService {
    execution: concurrent

    inputPort BatterySocket {
        Location: "socket://0.0.0.0:8085"
        
        Protocol: soap {
            .wsdl = "./BatteryService.wsdl";
            .wsdl.port = "BatteryServicePort";
            .dropRootValue = true
        }
        Interfaces: BatteryInterface
    }

    init {
        with (connectionInfo) {
            .username = "camunda";
            .password = "camunda";
            .host = "postgres";   // nome servizio Docker
            .port = 5432;         // porta interna container
            .database = "camunda";
            .driver = "postgresql"
        };
        connect@Database(connectionInfo)();
        println@Console("Battery Service avviato su porta 8085 (SOAP)")();
        println@Console("Connected to camunda DB")()
    }

    main {

        [ updateBattery( request )( response ) {
            vid = request.vehicleId;
            lvl = request.level;

            update@Database(
                "UPDATE vehicles SET battery_level = " + lvl +
                ", last_updated = CURRENT_TIMESTAMP " +
                "WHERE vehicle_id = '" + vid + "'"
            )(ur);

            println@Console("[BATTERY] Aggiornata " + vid + ": " + lvl + "%")()
        } ]

        [ getBattery( request )( response ) {
            vid = request.vehicleId;

            query@Database(
                "SELECT battery_level FROM vehicles WHERE vehicle_id = '" + vid + "'"
            )(res);

            if (#res.row == 1) {
                response.level = int(res.row[0].battery_level);
                println@Console("[BATTERY] GetBattery per " + vid + ": " + response.level + "%")()
            } else {
                println@Console("[BATTERY] GetBattery per " + vid + ": Veicolo non trovato, restituisco 0")();
                response.level = 0
            }
        } ]
    }
}
