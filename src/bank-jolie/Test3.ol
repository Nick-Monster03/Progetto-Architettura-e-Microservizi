include "console.iol"
include "BankInterface.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    println@Console( "--- CLIENT LUIGI (Test Eccezione Fondi) ---" )();
    
    req.userId = "luigi"; // Luigi ha solo 5.0 nel server
    req.amount = 100.0;   // Ne chiede 100.0
    req.cardNumber = "LUIGI-POOR-CARD";
    req.expiryTime = 300000;

    preAuthorize@BankService( req )( resp );

    if ( !resp.success ) {
        println@Console( "✅ TEST SUPERATO: Transazione rifiutata come previsto." )();
        println@Console( "   Errore Server: " + resp.errorMessage )();
        println@Console( "   Codice: " + resp.errorCode )()
    } else {
        println@Console( "❌ TEST FALLITO: Luigi non doveva essere autorizzato!" )()
    }
}