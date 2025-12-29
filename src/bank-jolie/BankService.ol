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

    // Correlation Set: lega il paymentToken generato in 'preAuthorize' 
    // a quello ricevuto in 'commitPayment'
    cset {
        paymentToken: PaymentRequest.paymentToken
    }

    main {
        // Fase 1: Pre-autorizzazione (apre la sessione)
        preAuthorize( request )( response ) {
            // Genera nuovo token univoco
            response.paymentToken = new;
            // Associa il token alla sessione corrente
            csets.paymentToken = response.paymentToken;
             
            response.success = true;
            response.message = "Pre-auth OK";

            println@Console( "--- [NEW SESSION] RICHIESTA RICEVUTA ---" )();
            println@Console( "Cliente: " + request.clientName )();
            println@Console( "Token (SID): " + response.paymentToken )()
        };

        // Variabile di sessione: importo bloccato
        amountBlocked = 10.0; 
        println@Console( "Stato Sessione: Bloccati " + amountBlocked + " EUR. In attesa di PaymentRequest..." )();

        // Fase 2: Conferma pagamento (chiude la sessione o continua a elaborare)
        commitPayment( request )( response ) {
            undef(response);
            println@Console( "--- [RESUME SESSION] PAGAMENTO RICEVUTO ---" )();
            println@Console( "Token ricevuto: " + request.paymentToken )();
            
            // Logica di confronto importo
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