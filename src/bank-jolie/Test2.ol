include "console.iol"
include "time.iol"
include "BankInterface.iol"

outputPort BankService_Auth {
    Location: "socket://localhost:8008"
    Protocol: soap 
    Interfaces: BankInterface
}


outputPort BankService_Cancel {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    println@Console( "--- CLIENT TOAD (Cancellazione) ---" )();
    
    req.userId = "toad";
    req.amount = 15.0;
    req.cardNumber = "TOAD-CARD-999";
    req.expiryTime = 300000;

    // Usiamo la porta 1
    preAuthorize@BankService_Auth( req )( resp );

    if ( resp.success ) {
        println@Console( "✅ Pre-Auth OK. Token: " + resp.authToken )();
        
        println@Console( "... Toad ci sta pensando (1 secondo) ..." )();
        sleep@Time( 1000 )();

        // 3. CANCEL AUTH
        cancel.authToken = resp.authToken;
        cancel.expired = false;
        cancel.reason = "Ho cambiato idea";

        println@Console( "Invio Cancellazione su porta dedicata..." )();
        
        // Usiamo lo scope di sicurezza sulla PORTA 2
        scope( oneWaySafety ) {
            install( default => 
                println@Console( "✅ Richiesta inviata (Ack implicito)." )()
            );
            
            // NOTA: Chiamata su BankService_Cancel
            cancelAuth@BankService_Cancel( cancel )
        };
        
        sleep@Time( 1000 )()
    }
}