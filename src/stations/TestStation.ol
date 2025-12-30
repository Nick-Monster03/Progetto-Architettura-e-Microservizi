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
    registerForInput@Console()();

    // --- TEST 1: Prenotazione con Successo (Happy Path) ---
    // Usiamo "v1" perché è inizializzato come libero nel tuo StationService
    println@Console( "1. Test Prenotazione Veicolo Libero (v1)..." )();
    with( reqReserve ) {
        .vehicleId = "v1";       
        .userId = "MarioRossi"   
    };
    reserve@StationService( reqReserve )( respReserve );
    
    println@Console( "   Esito: " + respReserve.message )();
    if ( respReserve.success ) {
        println@Console( "   [OK] Prenotazione riuscita." )()
    } else {
        println@Console( "   [FAIL] Errore imprevisto." )()
    };
    println@Console( "--------------------------------------" )();

    // --- TEST 2: Prenotazione Fallita (Veicolo Occupato) ---
    // Usiamo "v3" che nel tuo init è riservato a "user_b"
    println@Console( "2. Test Prenotazione Veicolo Occupato (v3)..." )();
    with( reqReserveFail ) {
        .vehicleId = "v3";       
        .userId = "MarioRossi"
    };
    reserve@StationService( reqReserveFail )( respReserveFail );

    println@Console( "   Esito: " + respReserveFail.message )();
    if ( !respReserveFail.success ) {
        println@Console( "   [OK] Sistema ha bloccato correttamente la prenotazione." )()
    } else {
        println@Console( "   [FAIL] Attenzione: Ho prenotato un veicolo non disponibile!" )()
    };
    println@Console( "--------------------------------------" )();

    // Simulo il tempo che passa mentre vado al veicolo
    println@Console( "...Mi reco al veicolo v1..." )();
    sleep@Time(1000)(); 

    // --- TEST 3: Sblocco Veicolo Prenotato (Unlock) ---
    // IMPORTANTE: Deve essere lo stesso ID e UTENTE della prenotazione (v1, MarioRossi)
    println@Console( "3. Test Sblocco Veicolo Prenotato (v1)..." )();
    with( reqUnlock ) {
        .vehicleId = "v1"; 
        .userId = "MarioRossi"
    };
    
    unlock@StationService( reqUnlock )( respUnlock );
    
    println@Console( "   Esito: " + respUnlock.message )();
    if ( respUnlock.success ) {
        println@Console( "   [OK] Veicolo sbloccato. SID Sessione: " + respUnlock.sid )()
    } else {
        println@Console( "   [FAIL] ERRORE Sblocco" )()
    };
    println@Console( "--------------------------------------" )();

    // Simula il tempo passato in viaggio
    println@Console( "...In viaggio..." )();
    sleep@Time(2000)(); 

    // --- TEST 4: Riconsegna Veicolo (Lock) ---
    println@Console( "4. Test Riconsegna Veicolo (Lock)..." )();
    if ( respUnlock.success ) {
        with( reqLock ) {
            .vehicleId = "v1";
            .stationId = "Stazione-Centrale";
            .sid = respUnlock.sid // Usiamo il SID ricevuto dalla unlock
        };

        lock@StationService( reqLock )( respLock );

        println@Console( "   Esito: " + respLock.message )();
        println@Console( "   Successo: " + respLock.success )()
    } else {
        println@Console( "   [SKIP] Salto il test di blocco perché lo sblocco è fallito." )()
    }
}