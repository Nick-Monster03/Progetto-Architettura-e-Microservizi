include "BankInterface.iol"
include "console.iol"
include "time.iol"

outputPort BankService {
    Location: "socket://localhost:8008"
    Protocol: soap {
        .wsdl = "./BankService.wsdl";
        .wsdl.port = "BankPort";  
    }
    Interfaces: BankInterface
}

main {
    
    // ==========================================
    // TEST 1: MARIO (Happy Path - Deve Funzionare)
    // ==========================================
    scope( TestMario ) {
        // Se Mario fallisce, è un errore del test
        install( default => println@Console("FAIL: Errore imprevisto su Mario: " + main_scope.default )() );
        println@Console( "\n--- TEST 1: Mario (Happy Path) ---" )();
        
        // 1. Pre-Autorizzazione
        authReq.clientName = "Mario";
        authReq.cardNumber = "1111-2222-3333-4444";
        preAuthorize@BankService( authReq )( authResp );
        token = authResp.paymentToken;
        println@Console( "[OK] PreAuth eseguita. Token: " + token )();
        
        sleep@Time( 100 )(); // Simuliamo noleggio

        // 2. Pagamento Finale
        payReq.amount = 15.50;
        payReq.paymentToken = token;
        commitPayment@BankService( payReq )( payResp );
        
        println@Console( "[OK] Risultato: " + payResp.message )();
        println@Console( ">>> TEST 1 SUPERATO" )()
    };

    // ==========================================
    // TEST 2: LUIGI (Fondi Insufficienti - Deve Fallire Subito)
    // ==========================================
    scope( TestLuigi ) {
        // Qui ci aspettiamo l'errore "InsufficientFunds"
        install( default => 
            println@Console( "[OK] Errore previsto catturato: " + TestLuigi.default.message )();
            println@Console( ">>> TEST 2 SUPERATO" )()
        );
        
        println@Console( "\n--- TEST 2: Luigi (Insufficient Funds) ---" )();
        
        authReq2.clientName = "Luigi";
        authReq2.cardNumber = "0000-0000-0000-0000"; // Ha solo 5 euro
        
        println@Console("Tentativo PreAuth Luigi (Atteso fallimento)...")();
        // Questa chiamata DEVE fallire
        preAuthorize@BankService( authReq2 )( authResp2 );
        
        println@Console( "FAIL: Luigi è riuscito a loggarsi! Doveva fallire." )()
    };

    // ==========================================
    // TEST 3: WARIO (Pagamento Rifiutato - Fallisce alla fine)
    // ==========================================
    scope( TestWario ) {
        // Qui ci aspettiamo l'errore "PaymentRefused"
        install( default => 
             println@Console( "[OK] Errore finale catturato: " + TestWario.default.message )();
             println@Console( ">>> TEST 3 SUPERATO" )()
        );
        
        println@Console( "\n--- TEST 3: Wario (Rich Man, Bad Payment) ---" )();
        
        // 1. Wario è ricco (10.000), la pre-auth (10€) DEVE passare
        authReq3.clientName = "Wario";
        authReq3.cardNumber = "9999-9999-9999-9999";
        preAuthorize@BankService( authReq3 )( authResp3 );
        token3 = authResp3.paymentToken;
        println@Console( "[OK] PreAuth Wario passata." )();
        
        sleep@Time( 100 )();
        
        // 2. Wario prova a pagare una cifra assurda (50.000€)
        payReq3.amount = 50000.0;
        payReq3.paymentToken = token3;
        
        println@Console("Tentativo pagamento 50.000 EUR (Saldo Wario: 10.000)...")();
        commitPayment@BankService( payReq3 )( payResp3 );

        println@Console( "FAIL: Wario ha pagato senza fondi sufficienti!" )()
    }

    // ==========================================
    // TEST 4: WALUIGI (Account Sospeso - Deve Fallire Subito)
    // ==========================================
    scope( TestWaluigi ) {
        // NUOVO FAULT DA CATTURARE
        install( default => 
             println@Console( "[OK] Errore AccountSuspended catturato: " + TestWaluigi.default.message )();
             println@Console( ">>> TEST 4 SUPERATO" )()
        );
        
        println@Console( "\n--- TEST 4: Waluigi (Suspended User) ---" )();
        
        authReq4.clientName = "Waluigi";
        authReq4.cardNumber = "6666-6666-6666-6666"; 
        
        println@Console("Tentativo PreAuth Waluigi (Utente sospeso ma con fondi)...")();
        
        // Questa chiamata deve lanciare AccountSuspended
        preAuthorize@BankService( authReq4 )( authResp4 );
        
        println@Console( "FAIL: Waluigi è riuscito a loggarsi nonostante la sospensione!" )()
    }
}