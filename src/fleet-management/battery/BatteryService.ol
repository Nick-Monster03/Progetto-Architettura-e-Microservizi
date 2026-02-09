include "BatteryInterface.iol"
include "console.iol"

service BatteryService {
    execution: concurrent

    inputPort BatterySocket {
        // Usa 0.0.0.0 per essere raggiungibile dagli altri container (fix Docker)
        Location: "socket://0.0.0.0:8085"
        
        Protocol: soap {
            .wsdl = "./BatteryService.wsdl";
            .wsdl.port = "BatteryServicePort";
            .dropRootValue = true
        }
        Interfaces: BatteryInterface
    }
    
    init {
        // Dati iniziali
        global.batteries.("car1") = 100;
        global.batteries.("car2") = 100
    }

    main {
        [ updateBattery( request )( response ) {
            synchronized( batteryLock ) {
                global.batteries.(request.vehicleId) = request.level
            };
            println@Console("[BATTERY] Aggiornata " + request.vehicleId + ": " + request.level + "%")()
        } ]

        [ getBattery( request )( response ) {
            synchronized( batteryLock ) {
                if ( is_defined( global.batteries.(request.vehicleId) ) ) {
                    response.level = global.batteries.(request.vehicleId)
                } else {
                    response.level = 100 
                }
            }
        } ]
    }
}