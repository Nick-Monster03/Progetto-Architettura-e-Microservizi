// IMPORTAZIONE AGGIORNATA
from console import Console
include "../battery/BatteryInterface.iol" // Assicurati che questo percorso sia corretto

service BatteryServiceMock {
    execution: concurrent

    inputPort BatteryPort {
        Location: "socket://localhost:8085" // Porta attesa dal Gateway
        Protocol: sodep
        Interfaces: BatteryInterface
    }

    embed Console as Console

    main {
        [ getBattery( request )( level ) {
            println@Console("[BATTERY] Richiesta livello per: " + request.vehicleId)();
            level = 85 // Restituisce sempre 85%
        } ]
    }
}