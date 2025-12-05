include "BankInterface.iol"
include "console.iol"

// Servizio Bancario ACMEMobility
service BankService {
    
    // Esecuzione concorrente: ogni 'token' genera un processo (sessione) separato
    execution: concurrent

    inputPort BankPort {
        location: "socket://localhost:8008"
        protocol: soap 
        interfaces: BankInterface
    }

    // Definizione del Correlation Set 
    // Questo permette a Jolie di capire a quale sessione aperta inviare la richiesta di commitPayment
    cset {
        
        paymentToken: CommitRequest.token
    }

    embed Console as Console

    main {
        preAuthorize( request )( response ) {
            response.token = new;
            
            csets.paymentToken = response.token;
            
            amountBlocked = request.amount;
            
            println@Console( "SESSIONE AVVIATA. Token generato: " + response.token )();
            println@Console( "Importo bloccato (cauzione): " + amountBlocked )()
        }; 

        commitPayment( request )( ) {
            
            if ( request.finalAmount <= amountBlocked ) {
                println@Console( "Pagamento coperto interamente dalla cauzione." )()
            } else {
                diff = request.finalAmount - amountBlocked;
                println@Console( "Addebito differenza di " + diff + " oltre la cauzione." )()
            };

            println@Console( "TRANSAZIONE CONCLUSA per token: " + csets.paymentToken )()
        }
    }
}
