include "BankInterface.iol"
from console import Console

service BankService {
    
    execution: concurrent

    inputPort BankPort {
        location: "socket://localhost:8008"
        protocol: soap {
            .wsdl = "./BankService.wsdl";      
            .wsdl.port = "BankPortServicePort" 
        }
        interfaces: BankInterface
    }

    cset {
        paymentToken: CommitRequest.token
    }

    embed Console as Console 

    main {
        preAuthorize( request )( response ) {
            response.token = new;
            csets.paymentToken = response.token;
            amountBlocked = 10.0; //Di default blocca sempre 10 euro
            
            println@Console( "--- RICHIESTA RICEVUTA ---" )();
            println@Console( "Utente: " + request.userId )();
            println@Console( "Importo bloccato: " + amountBlocked )();
            println@Console( "Token generato: " + response.token )()
        };

        commitPayment( request )( ) {
            println@Console( "--- COMMIT RICEVUTA ---" )();
            println@Console( "Token: " + request.token )();
            
            if ( request.finalAmount <= amountBlocked ) {
                println@Console( "Pagamento OK. Rilascio cauzione." )()
            } else {
                diff = request.finalAmount - amountBlocked;
                println@Console( "Pagamento OK. Addebito differenza: " + diff )()
            }
        }
    }
}