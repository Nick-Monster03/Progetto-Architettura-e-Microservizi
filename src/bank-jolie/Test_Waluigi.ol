include "console.iol"
include "time.iol"
include "BankInterface.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    println@Console( "[WALUIGI] Inizio procedura (VELOCE)..." )();
    req.userId = "waluigi";
    req.amount = 10.0;
    req.cardNumber = "WALUIGI-SILVER"; 
    req.expiryTime = 300000;

    preAuthorize@BankService( req )( resp );

    if ( resp.success ) {
        println@Console( "[WALUIGI] Autenticato. Token: " + resp.authToken )();
        println@Console( "[WALUIGI] ... Attendo solo 2 secondi ..." )();
        
        sleep@Time( 2000 )(); 

        pay.authToken = resp.authToken;
        pay.finalAmount = 5.0; 
        pay.duration = 5;
        pay.kilometers = 2.0;
        pay.batteryLevel = 90;

        println@Console( "[WALUIGI] Pago ora." )();
        commitPayment@BankService( pay )( res );
        
        println@Console( "[WALUIGI] Pagamento concluso: " + res.receiptId )()
    }
}