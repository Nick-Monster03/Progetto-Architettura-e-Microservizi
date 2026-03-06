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
        
        global.vehicles.("car1").battery = 76;
        global.vehicles.("car2").battery = 80;
        global.vehicles.("car3").battery = 100;
        println@Console("Battery Service avviato su porta 8085 (SOAP)")()
    }
    

    main {
        [ updateBattery( request )( response ) {
            synchronized( batteryLock ) {
                global.vehicles.(request.vehicleId).battery = request.level
            };
            println@Console("[BATTERY] Aggiornata " + request.vehicleId + ": " + request.level + "%")()
        } ]

        [ getBattery( request )( response ) {
            synchronized( batteryLock ) {
                if ( is_defined( global.vehicles.(request.vehicleId).battery ) ) {
                    response.level = global.vehicles.(request.vehicleId).battery
                    println@Console("[BATTERY] GetBattery per " + request.vehicleId + ": " + response.level + "%")()
                } else {
                    println@Console("[BATTERY] GetBattery per " + request.vehicleId + ": Veicolo non trovato, restituisco 100%")()
                    response.level = 100 
                }
            }
        } ]
    }
}