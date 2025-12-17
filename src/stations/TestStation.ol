include "StationInterface.iol"
include "console.iol"
include "time.iol" // Include the time library for sleep functionality

outputPort StationService {
    Location: "socket://localhost:8083"
    Protocol: soap {
        // Opzionale nel client per test rapidi, ma utile per coerenza
        .wsdl = "./StationService.wsdl"; 
        .dropRootValue = true
    }
    Interfaces: StationInterface
}

main {
    // --- TEST 1: Sblocco Veicolo (Unlock) ---
    println@Console( "1. Test Sblocco Veicolo..." )();
    with( reqUnlock ) {
        .vehicleId = "v-test"; // Veicolo inizializzato nel tuo init
        .userId = "MarioRossi"
    };
    
    unlock@StationService( reqUnlock )( respUnlock );
    
    println@Console( "   Esito: " + respUnlock.message )();
    if ( respUnlock.success ) {
        println@Console( "   SID Sessione: " + respUnlock.sid )()
    } else {
        println@Console( "   ERRORE Sblocco" )()
    };
    println@Console( "--------------------------------------" )();

    // Simula il tempo passato tra sblocco e blocco
    sleep@Time(3000)(); 

    // --- TEST 2: Blocco Veicolo (Lock) ---
    println@Console( "2. Test Riconsegna Veicolo (Lock)..." )();
    with( reqLock ) {
        .vehicleId = "v-test";
        .stationId = "Stazione-Centrale";
        .sid = respUnlock.sid // Usiamo il SID ricevuto prima (se previsto dalla logica)
    };

    lock@StationService( reqLock )( respLock );

    println@Console( "   Esito: " + respLock.message )();
    println@Console( "   Successo: " + respLock.success )()
}