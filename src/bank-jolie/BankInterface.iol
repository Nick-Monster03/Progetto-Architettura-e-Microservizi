type PreAuthRequest: void {
    .userId: string     // Identificativo dell'utente
    .amount: double     // Importo da bloccare (es. 10.0) [cite: 13]
}

// Risposta con il token di conferma della banca
type PreAuthResponse: void {
    .token: string      // Token univoco per la transazione [cite: 14]
}

// Tipo per il pagamento finale
type CommitRequest: void {
    .token: string      // Il token ricevuto nella fase precedente
    .finalAmount: double // L'importo effettivo da addebitare [cite: 19]
}

// Definizione dell'interfaccia del servizio
interface BankInterface {
    RequestResponse:
        // Operazione 1: Blocca i fondi (cauzione) [cite: 97]
        preAuthorize( PreAuthRequest )( PreAuthResponse ),
        
        // Operazione 2: Addebito finale e sblocco cauzione [cite: 98]
        commitPayment( CommitRequest )( void )
}


