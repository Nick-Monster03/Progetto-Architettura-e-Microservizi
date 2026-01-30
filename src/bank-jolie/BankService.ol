include "BankInterface.iol"
include "console.iol"
include "time.iol"

service BankService {
    
    execution: concurrent

    inputPort BankPort {
        location: "socket://0.0.0.0:8008"
        
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
        paymentToken: PaymentRequest.paymentToken CancelAuthRequest.token
    }


    init {
        // Inizializzazione Database Utenti fittizio
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
        // Fase 1: Pre-autorizzazione (apre la sessione)
        preAuthorize( request )( response ) {
            client = request.clientName;
            
            install(InsufficientFunds =>
                println@Console("FAIL: Non ci sono abbastanza fondi: " + client)()
            );

            install( AccountSuspended => 
                println@Console("FAIL: Utente sospeso: " + client)()
            );    
        
            synchronized( balanceLock ) {
                // Ricerca utente
                userIndex = -1; // Default not found
                for( i=0, i<#global.users, i++ ) {
                    if ( global.users[i].name == client ) {
                        userIndex = i
                    }
                };
                
                // Se utente non trovato o sospeso
                if ( userIndex == -1 || global.users[userIndex].state == "suspended" ) {
                     with( error ) { 
                        .message = "Account inesistente o bloccato." 
                     };
                     throw( AccountSuspended, error )
                };
                
                currentBalance = global.users[userIndex].balance;
                
                if ( currentBalance < global.CAUZIONE_STD ) {
                    with( error ) { .message = "Fondi insufficienti. Saldo: " + currentBalance};
                    throw( InsufficientFunds, error )
                } else {
                    // Blocco cauzione
                    global.users[userIndex].balance = currentBalance - global.CAUZIONE_STD
                }
            };

            // Setup Sessione
            sessionUserIndex = userIndex;
            amountBlocked = global.CAUZIONE_STD; 
            sessionUserName = client; 

            response.paymentToken = new;
            csets.paymentToken = response.paymentToken; 

            response.success = true;
            response.message = "Pre-auth OK"
        };

        // Fase 2: Conferma Pagamento
        [ commitPayment( request )( response ) {
            undef(response);
            
            install( PaymentRefused => 
                println@Console( "FAIL: Pagamento rifiutato per " + sessionUserName + ": " + PaymentRefused.message )()
            );

            synchronized( balanceLock ) {
                current = global.users[sessionUserIndex].balance;

                if ( request.amount <= global.CAUZIONE_STD ) {
                    // Rimborso parziale
                    diff = amountBlocked - request.amount;
                    global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance + diff;
                    
                    response.success = true;
                    response.message = "Pagamento OK ("+request.amount+"). Rimborsati: " + diff
                } else {
                    // Addebito extra
                    extra = request.amount - global.CAUZIONE_STD;
                    
                    if ( current < extra ) { 
                        global.users[sessionUserIndex].state = "suspended";
                        with( error ) { 
                            .message = "Pagamento Rifiutato. Saldo insufficiente per extra: " + extra 
                        };
                        println@Console( "FAIL: " + error.message )();
                        throw( PaymentRefused, error )
                    };
                    
                    global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance - extra;
                    
                    response.success = true;
                    response.message = "Pagamento OK ("+request.amount+"). Addebito extra: " + extra
                }
            };

            response.txId = "TX-" + request.paymentToken;
            println@Console( response.message )()
        } ]

        // Fase 3: Annullamento (es. errore stazione)
        [ cancelAuth( request ) ]{
            println@Console( "--- Annullamento per " + sessionUserName )();
            
            synchronized( balanceLock ) {
                global.users[sessionUserIndex].balance = global.users[sessionUserIndex].balance + amountBlocked;
                println@Console( "Cauzione sbloccata (" + amountBlocked + "). Nuovo saldo: " + global.users[sessionUserIndex].balance )()
            }
        } 
    }
}