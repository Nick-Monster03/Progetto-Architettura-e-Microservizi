include "BankInterface.iol"
include "console.iol"
include "time.iol"

service BankService {
    
    execution: concurrent

    inputPort BankPort {
        location: "socket://localhost:8008"
        interfaces: BankInterface 
        Protocol: soap 
    }

    cset {
        paymentToken: PaymentRequest.paymentToken 
    }


    init {
        global.users[0].name = "Mario";
        global.users[0].balance = 1000.0;
        global.users[0].state = "active";
        
        global.users[1].name = "Luigi";
        global.users[1].balance = 5.0;
        global.users[1].state = "active";
        
        global.users[2].name = "Wario";
        global.users[2].balance = 10000.0;
        global.users[2].state = "active";

        global.users[3].name = "Waluigi";
        global.users[3].balance = 500.0; 
        global.users[3].state = "suspended";
        
        global.CAUZIONE_STD = 10.0
            
    }

    main {
      
        preAuthorize( request )( response ) {
            client = request.clientName;
            
            install(InsufficientFunds =>
                println@Console("FAIL: Non ci sono abbastanza fondi: " + client)()
            );

		    install( AccountSuspended => 
                println@Console("FAIL: Utente sospeso: " + client)()
            );    
		    

            synchronized( balanceLock ) {
                for( i=0, i<#global.users, i++ ) {
                    if ( global.users[i].name == client ) {
                        userIndex = i
                    }
                };
                if ( global.users[userIndex].state == "suspended" ) {
                     with( error ) { 
                        .message = "Account bloccato per insolvenza precedente." 
                     };
                     throw( AccountSuspended, error )
                };
                currentBalance = global.users[userIndex].balance;
                
                if ( currentBalance < global.CAUZIONE_STD ) {
                    //println@Console( "DEBUG: Saldo attuale " + currentBalance + " insufficiente per cauzione." )();
                    with( error ) { .message = "Fondi insufficienti. Saldo: " + currentBalance};
                    throw( InsufficientFunds, error )
                } else {
                    global.users[userIndex].balance = currentBalance - global.CAUZIONE_STD
                    //println@Console( "DEBUG: Blocco " + global.CAUZIONE_STD + " EUR eseguito. Nuovo saldo: " + global.users[userIndex].balance )()
                }
            };

            sessionUserIndex = userIndex;
            amountBlocked = global.CAUZIONE_STD; 
            sessionUserName = client; // Solo per i log

            response.paymentToken = new;
            csets.paymentToken = response.paymentToken; 

            response.success = true;
            response.message = "Pre-auth OK"

            //println@Console( "Token generato: " + response.paymentToken )()
        };

        
        [ commitPayment( request )( response ) {
            undef(response);
            //println@Console( "--- [RESUME SESSION] Pagamento ricevuto per " + sessionUserName )();
            install( PaymentRefused => 
                println@Console( "FAIL: Pagamento rifiutato per " + sessionUserName + ": " + PaymentRefused.message )()
            );

            synchronized( balanceLock ) {
                current = global.users[sessionUserIndex].balance;

                if ( request.amount <= global.CAUZIONE_STD ) {
                    diff = amountBlocked - request.amount;
                    global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance + diff;
                    
                    response.success = true;
                    response.message = "Pagamento OK ("+request.amount+"). Rimborsati: " + diff
                } else {
                    extra = request.amount - global.CAUZIONE_STD;
                    // println@Console( "DEBUG: " + request.amount )();
                    // println@Console( "DEBUG: " + extra )();
                    if ( current < extra ) { //se un utente non ha abbastanza soldi per pagare l'extra viene sopseso dal servizio
                        global.users[sessionUserIndex].state = "suspended"
                        with( error ) { 
                            .message = "Pagamento Rifiutato. Saldo attuale (" + current + ") insufficiente per l'extra di " + extra 
                        };
                        println@Console( "FAIL: " + error.message )();
                        throw( PaymentRefused, error )
                        //println@Console( "DEBUG WARNING: Utente va in rosso per pagare l'extra!" )()
                    };
                    global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance - extra;
                    
                    response.success = true;
                    response.message = "Pagamento OK ("+request.amount+"). Addebito extra: " + extra
                    //println@Console( "DEBUG: Addebito extra di " + extra + ". Nuovo saldo: " + global.users[sessionUserIndex].balance )()
                }
            };
            //println@Console( "DEBUG: Generazione TX ID per token " + request.paymentToken )();
            response.txId = "TX-" + request.paymentToken;
            println@Console( response.message )()
        } ]

        [ cancelAuth( request ) ]{
            println@Console( "--- Annullamento per " + sessionUserName )();
            
            synchronized( balanceLock ) {
                global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance + amountBlocked;
                println@Console( "Cauzione sbloccata (" + amountBlocked + "). Nuovo saldo: " + global.users[sessionUserIndex].balance )()
            }
        } 
    }
}