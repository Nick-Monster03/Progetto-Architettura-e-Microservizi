include "BatteryInterface.iol"
include "console.iol"

service BatteryService {
    execution: concurrent
    
    

    inputPort BatterySocket {
        Location: "socket://localhost:8085"
        Protocol: sodep
        Interfaces: BatteryInterface
    }
    
    init {
        // Dati iniziali
        global.batteries.("v-test") = 100
    }

    main {
        [ updateBattery( request )( response ) {
            global.batteries.(request.vehicleId) = request.level;
            println@Console("[BATTERY] Aggiornata " + request.vehicleId + ": " + request.level + "%")()
        } ]

        [ getBattery( request )( level ) {
            if ( is_defined( global.batteries.(request.vehicleId) ) ) {
                level = global.batteries.(request.vehicleId)
            } else {
                level = 100 
            }
        } ]
    }
}