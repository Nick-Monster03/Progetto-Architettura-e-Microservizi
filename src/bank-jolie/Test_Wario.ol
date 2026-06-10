include "console.iol"
include "time.iol"
include "BankInterface.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    println@Console( "[WARIO] Inizio procedura (LENTO)..." )();
    req.userId = "wario";
    req.amount = 50.0;
    req.cardNumber = "WARIO-GOLD"; 
    req.expiryTime = 300000;

    preAuthorize@BankService( req )( resp );

    if ( resp.success ) {
        println@Console( "[WARIO] Autenticato. Token: " + resp.authToken )();
        println@Console( "[WARIO] ... Mi addormento per 10 SECONDI (Lancia Waluigi ora!) ..." )();
        
        // Simula una sessione lunga
        sleep@Time( 10000 )(); 

        pay.authToken = resp.authToken;
        pay.finalAmount = 60.0; 
        pay.duration = 100;
        pay.kilometers = 50.0;
        pay.batteryLevel = 10;

        println@Console( "[WARIO] Mi sono svegliato. Pago ora." )();
        commitPayment@BankService( pay )( res );
        
        println@Console( "[WARIO] Pagamento concluso: " + res.receiptId )()
    }
}