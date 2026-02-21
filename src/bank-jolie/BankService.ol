include "console.iol"
include "string_utils.iol"
include "time.iol"
include "BankInterface.iol"

service BankService {
    execution: concurrent 

    inputPort BankPort {
        Location: "socket://0.0.0.0:8008"
        Protocol: soap{
            .wsdl = "BankService.wsdl",
        }
        Interfaces: BankInterface
    }

    cset {
        authToken: PreAuthorizeResponse.authToken  
                CommitPaymentRequest.authToken
                CommitPenaltyRequest.authToken
                CancelAuthRequest.authToken
    }

    init {
        global.balances.("mario") = 1000.0; 
        global.balances.("luigi") = 5.0; 
        global.balances.("peach") = 100.0;
        global.balances.("wario") = 1000.0;
        global.balances.("waluigi") = 1000.0;
        global.balances.("toad") = 100.0;
        
        global.transactionCounter = 0; 
        println@Console( "Bank Service avviato (Porta 8008)" )()
    }

    main {
        
        preAuthorize( request )( response ) {
            
            userId = request.userId;
            amount = request.amount; // Sempre 10$
            session.userId = userId; 
            
     
            
            println@Console( "\n[BANK] === PRE-AUTHORIZE (" + userId + ") ===" )();

            synchronized( balanceLock ) {
                
                // Inizializza utente se non esiste
                if( !is_defined( global.balances.(userId) ) ) {
                    global.balances.(userId) = 100.0
                };
                
                currentBalance = global.balances.(userId);

                if( currentBalance >= amount ) {
                    
                    // Generazione Token
                    getCurrentTimeMillis@Time()( timestamp );
                    global.transactionCounter++;
                    response.authToken = "TOK_" + userId + "_" + global.transactionCounter;
                    
                    // IMPOSTAZIONE CSET
                    csets.authToken = response.authToken;
                    
                    // Salvataggio stato sessione
                    session.userId = userId;
                    session.blockedAmount = amount;
                    
                    // Blocco fondi
                    global.balances.(userId) = currentBalance - amount;
                    
                    // Compilazione Risposta
                    response.success = true;
                    response.blockedAmount = amount;
                    
                    println@Console( "[BANK] Token: " + response.authToken )();
                    println@Console( "[BANK] Blocked: €" + amount )()
                    
                } else {
                    response.success = false;
                    response.errorCode = "INSUFFICIENT_FUNDS";
                    response.errorMessage = "Saldo insufficiente";
                    println@Console( "[BANK]  Insufficient funds" )()
                }
            }
        };
        
        if ( response.success ) {
            undef(response);
            [ cancelAuth( request ) ] {
                // --- CASO 1: CANCELLAZIONE (OneWay) ---
                println@Console( "\n[BANK] === CANCEL AUTH (" + session.userId + ") ===" )();
                
                // Campi request: .reason, .isExpired
                
                synchronized( balanceLock ) {
                    if( request.isExpired ) {
                        // Se scaduta, tratteniamo la cauzione (logica simulata)
                        println@Console( "[BANK] Expired: Deposit retained." )()
                    } else {
                        // Rimborso totale
                        currentBalance = global.balances.(session.userId);
                        global.balances.(session.userId) = currentBalance + session.blockedAmount;
                        println@Console( "[BANK] Cancelled: Deposit released.\n New balance: €" + global.balances.(session.userId) )()
                    }
                }
                sleep@Time( 2000 )() 
            }
            
            [ commitPayment( request )( response ) {
                // --- CASO 2: PAGAMENTO CORSA ---
                println@Console( "\n[BANK] === COMMIT PAYMENT (" + session.userId + ") ===" )();
                println@Console("token: " + request.authToken)();
                // Campi request: .finalAmount, .duration, .kilometers, .batteryLevel
                finalAmount = request.finalAmount;
                
                synchronized( balanceLock ) {
                    currentBalance = global.balances.(session.userId);
                    
                    if( finalAmount <= session.blockedAmount ) {
                        // A: Costa meno della cauzione -> Rimborso differenza
                        refund = session.blockedAmount - finalAmount;
                        global.balances.(session.userId) = currentBalance + refund;
                        
                        response.success = true;
                        response.chargedAmount = finalAmount;
                        response.receiptId = "RCP_PAY_" + session.userId;
                        
                        println@Console( "[BANK] Success. Refund: €" + refund )()
                        
                    } else {
                        // B: Costa più della cauzione -> Addebito extra
                        extra = finalAmount - session.blockedAmount;
                        
                        if( currentBalance >= extra ) {
                            global.balances.(session.userId) = currentBalance - extra;
                            
                            response.success = true;
                            response.chargedAmount = finalAmount;
                            response.receiptId = "RCP_PAY_" + session.userId;
                            
                            println@Console( "[BANK] Success. Extra charge: €" + extra )()
                        } else {
                            // C: Insolvenza
                            response.success = false;
                            response.errorCode = "INSUFFICIENT_FUNDS";
                            response.errorMessage = "Fondi insufficienti per saldo finale";
                            
                            println@Console( "[BANK]  Insolvency on payment" )()
                        }
                    }
                    println@Console( "[BANK] Saldo sul conto di " + session.userId + ": €" + global.balances.(session.userId) )()
                }
            } ] 
            
            [ commitPenalty( request )( response ) {
                println@Console( "\n[BANK] === COMMIT PENALTY (" + session.userId + ") ===" )();
    
                penaltyAmount = request.penaltyAmount;
                
                synchronized( balanceLock ) {
                    
                    // Cauzione già bloccata, tratteniamo quanto richiesto
                    if( penaltyAmount < session.blockedAmount ) {
                        // Rimborso parziale
                        refund = session.blockedAmount - penaltyAmount;
                        currentBalance = global.balances.(session.userId);
                        global.balances.(session.userId) = currentBalance + refund;
                        println@Console( "[BANK] Partial refund: €" + refund )()
                    } else {
                        println@Console( "[BANK] Full deposit retained" )()
                    }
                    
                    response.success = true;
                    response.chargedAmount = penaltyAmount;
                    getCurrentTimeMillis@Time()( ts );
                    response.receiptId = "RCP_PEN_" + session.userId + "_" + ts;
                    println@Console( "[BANK] Saldo sul conto di " + session.userId + ": €" + global.balances.(session.userId) )()
                }
            } ]
        }; 
        
        println@Console( "[BANK] Session Closed for " + session.userId + "\n" )()
    }
}