include "BankInterface.iol"
// include "console.iol"  <-- Puoi commentare anche questo per ora, o lasciarlo

// Servizio Bancario ACMEMobility
service BankService {
    
    execution: concurrent

    inputPort BankPort {
        location: "socket://localhost:8008"
        protocol: soap 
        interfaces: BankInterface
    }

    cset {
        paymentToken: CommitRequest.token
    }

    // embed Console as Console   <-- COMMENTA QUESTA RIGA

    main {
        preAuthorize( request )( response ) {
            response.token = new;
            csets.paymentToken = response.token;
            
            amountBlocked = request.amount
            
            // println@Console( "SESSIONE AVVIATA..." )();  <-- COMMENTA I PRINT
            // println@Console( "Importo bloccato..." )()
        };

        commitPayment( request )( ) {
            
            if ( request.finalAmount <= amountBlocked ) {
                // println@Console( "Pagamento coperto..." )()
                nullProcess // Aggiungi questo se l'if rimane vuoto
            } else {
                diff = request.finalAmount - amountBlocked
                // println@Console( "Addebito differenza..." )()
            }
            
            // println@Console( "TRANSAZIONE CONCLUSA..." )()
        }
    }
}