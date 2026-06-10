include "console.iol"
include "time.iol"
include "BankInterface.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    println@Console( "--- CLIENT MARIO (Pagamento Standard) ---" )();
    
    req.userId = "mario";
    req.amount = 10.0;
    req.cardNumber = "MARIO-CARD-123";
    req.expiryTime = 300000;

    println@Console( "Invio Pre-Auth..." )();
    preAuthorize@BankService( req )( resp );

    if ( resp.success ) {
        println@Console( "Pre-Auth OK. Token: " + resp.authToken )();
        
        println@Console( "... Mario sta guidando (attendi 2 secondi) ..." )();
        sleep@Time( 2000 )();

        pay.authToken = resp.authToken;
        pay.finalAmount = 5.0; 
        pay.duration = 15;
        pay.kilometers = 3.0;
        pay.batteryLevel = 80;

        println@Console( "Invio Pagamento..." )();
        commitPayment@BankService( pay )( payResp );
        
        if ( payResp.success ) {
            println@Console( "Pagamento Completato. Ricevuta: " + payResp.receiptId )()
        } else {
            println@Console( "Errore Pagamento: " + payResp.errorMessage )()
        }
    } else {
        println@Console( "Errore Pre-Auth: " + resp.errorMessage )()
    }
}