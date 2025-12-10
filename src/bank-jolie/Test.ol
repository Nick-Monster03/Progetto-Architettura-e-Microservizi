from console import Console
include "BankInterface.iol"

service TestClient {
    embed Console as Console

    outputPort BankService {
        location: "socket://localhost:8008"
        protocol: soap {
            .wsdl = "./BankService.wsdl"
        }
        interfaces: BankInterface
    }

    main {
        println@Console("Tento la connessione al server sulla porta 8008...")();
        
        with( preAuthReq ) {
            .userId = "MarioRossi";
            .veichleId = "AB123CD"
        };
        
        println@Console("Invio richiesta pre-autorizzazione...")();
        
        scope( call ) {
            install( default => 
                v = main.exception;
                println@Console("Errore: " + v.name )();
                println@Console("Dettagli: " + v )()
            );

            
            preAuthorize@BankService( preAuthReq )( preAuthRes );
            token = preAuthRes.token;
            println@Console( "Connessione OK! Token ricevuto: " + token )();

            with( commitReq ) {
                .token = token;
                .userId = preAuthReq.userId;
                .veichleId = preAuthReq.veichleId;
                .finalAmount = 8.50
            };
            
            println@Console("Invio commit pagamento...")();
            commitPayment@BankService( commitReq )();
            println@Console("Pagamento completato!")()
        }
    }
}