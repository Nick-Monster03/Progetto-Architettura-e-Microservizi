include "BankInterface.iol"
include "console.iol"
include "time.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap
    Interfaces: BankInterface
}

main {
    
    println@Console( "1. Invio richiesta Pre-Auth..." )();
    authReq.clientName = "MarioRossi";
    authReq.cardNumber = "1234-5678-9012-3456";
    
    preAuthorize@BankService( authReq )( authResp );

    if ( authResp.success ) {
        token = authResp.paymentToken;
        println@Console( "   OK! Token ricevuto: " + token )();
        println@Console( "   (Sessione creata sul server. Attendo 2 secondi...)" )()
    } else {
        println@Console( "   Errore Pre-Auth!" )()
    };

    // Simuliamo il tempo del viaggio
    sleep@Time( 2000 )();

    
    println@Console( "2. Invio richiesta Pagamento Finale..." )();
    
    payReq.paymentToken = token;  
    executePayment@BankService( payReq )( payResp );
    
    println@Console( "   Risposta Server: " + payResp.message )();
    println@Console( "   ID Transazione: " + payResp.txId )()
}