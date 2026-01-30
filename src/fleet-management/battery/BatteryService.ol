include "BatteryInterface.iol"
include "console.iol"

service BatteryService {
    execution: concurrent

    inputPort BatterySocket {
        // Usa 0.0.0.0 per essere raggiungibile dagli altri container (fix Docker)
        Location: "socket://0.0.0.0:8085"
        
        // Usa SOAP come richiesto dalla traccia del progetto
        Protocol: soap {
            .wsdl = "./BatteryService.wsdl";
            .wsdl.port = "BatteryServicePort";
            .dropRootValue = true
        }
        Interfaces: BatteryInterface
    }
    
    init {
        // Dati iniziali
        global.batteries.("v-test") = 100
    }

    main {
        [ updateBattery( request )( response ) {
            synchronized( batteryLock ) {
                global.batteries.(request.vehicleId) = request.level
            };
            println@Console("[BATTERY] Aggiornata " + request.vehicleId + ": " + request.level + "%")()
        } ]

        [ getBattery( request )( level ) {
            synchronized( batteryLock ) {
                if ( is_defined( global.batteries.(request.vehicleId) ) ) {
                    level = global.batteries.(request.vehicleId)
                } else {
                    level = 100 
                }
            }
        } ]
    }
}