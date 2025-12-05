// Importiamo l'interfaccia definita precedentemente
include "BankInterface.iol"
// Importiamo la console per il logging [cite: 4928]
include "console.iol"

// Definizione del servizio Bancario
service BankService {
    
    // Esecuzione concorrente per gestire più richieste simultanee [cite: 501]
    execution: concurrent

    // Configurazione della porta di input (dove il servizio ascolta)
    inputPort BankPort {
        location: "socket://localhost:8008" // Indirizzo e porta [cite: 683]
        protocol: soap                      // Protocollo richiesto dal progetto [cite: 1254]
        interfaces: BankInterface           // Interfaccia esposta
    }

    // Embedding della console per stampare log a video [cite: 2283]
    embed Console as Console

    main {
        // Implementazione preliminare dell'operazione di pre-autorizzazione
        [ preAuthorize( request )( response ) {
            // Logica simulata: generiamo un token fittizio
            token = "BANK-TOKEN-" + new;
            response.token = token;
            
            // Log dell'operazione [cite: 2287]
            println@Console( "Ricevuta pre-autorizzazione per utente: " + request.userId )()
        }]

        // Implementazione preliminare del pagamento finale
        [ commitPayment( request )( ) {
            println@Console( "Pagamento finale confermato per token: " + request.token )()
        }]
    }
}
