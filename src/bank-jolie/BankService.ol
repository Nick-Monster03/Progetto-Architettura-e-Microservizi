include "BankInterface.iol"
include "console.iol"
include "time.iol"

service BankService {
    
    execution: concurrent

    inputPort BankPort {
        location: "socket://localhost:8008"
        protocol: soap {
            .wsdl = "./BankService.wsdl";      
            .wsdl.port = "BankPortServicePort";
            .dropRootValue = true
        }
        interfaces: BankInterface
    }

    cset {
        paymentToken: PaymentRequest.paymentToken
    }

    // embed Console as Console 
    // embed Time as Time

    main {
        preAuthorize( request )( response ) {
            response.paymentToken = new;
            
            csets.paymentToken = response.paymentToken;
             
            response.success = true;
            response.message = "Pre-auth OK";

            println@Console( "--- [NEW SESSION] RICHIESTA RICEVUTA ---" )();
            println@Console( "Cliente: " + request.clientName )();
            println@Console( "Token (SID): " + response.paymentToken )()
        };

        amountBlocked = 10.0; 
        println@Console( "Stato Sessione: Bloccati " + amountBlocked + " EUR. In attesa di PaymentRequest..." )();

        executePayment( request )( response ) {
            undef(response);
            println@Console( "--- [RESUME SESSION] PAGAMENTO RICEVUTO ---" )();
            println@Console( "Token ricevuto: " + request.paymentToken )();
            
            if ( request.amount <= amountBlocked ) {
                diff = amountBlocked - request.amount;
                response.success = true;
                response.message = "Pagamento OK. Rilascio: " + diff
            } else {
                extra = request.amount - amountBlocked;
                response.success = true;
                response.message = "Pagamento OK. Addebito extra: " + extra
            };
            response.txId = "TX-" + request.paymentToken;
            println@Console( response.message )();
            sleep@Time( 500 )()
        }
    }
}