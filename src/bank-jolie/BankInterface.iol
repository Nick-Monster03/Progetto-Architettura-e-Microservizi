type PreAuthorizeRequest {
    .userId: string
    .amount: double      // Importo da bloccare (es. 10.00 EUR per cauzione)
    .cardNumber: string
    .isRiservation:bool
}

type PreAuthorizeResponse {
    .success: bool
    .authToken?: string   // Token di autorizzazione se success=true
    .errorCode?: string   // Codice errore se success=false
    .errorMessage?: string
    .blockedAmount?: double
}

type CancelAuthRequest {
    .authToken: string
    .isExpired: bool        // true se la cancellazione è avvenuta dopo i 25 minuti dalla prenotazione
    .reason?: string      
}

type CommitPaymentRequest {
    .authToken: string
    .finalAmount: double  // Importo finale da addebitare
    .duration: int        // Minuti di noleggio
    .kilometers: double   // Km percorsi
    .batteryLevel: int    // Livello batteria finale (0-100)
    .penalty?: double     // Eventuale penale (es. batteria < 15% oppure ritiro dopo 25 min)
}

type CommitPaymentResponse {
    .success: bool
    .receiptId?: string   // ID della ricevuta se success=true
    .chargedAmount?: double
    .errorCode?: string   // Codice errore se success=false
    .errorMessage?: string
}

type CommitPenaltyRequest {
    .authToken: string
    .penaltyAmount: double  // Importo penalità (es. 10 EUR per mancato ritiro)
    .reason: string         // Motivo (es. "Timeout scaduto", "Mancato ritiro")
}

type CommitPenaltyResponse {
    .success: bool
    .receiptId?: string
    .chargedAmount?: double
    .errorMessage?: string
}


interface BankInterface {
    RequestResponse:
        preAuthorize(PreAuthorizeRequest)(PreAuthorizeResponse),
        commitPayment(CommitPaymentRequest)(CommitPaymentResponse),
        commitPenalty(CommitPenaltyRequest)(CommitPenaltyResponse)
    OneWay:
        cancelAuth(CancelAuthRequest)
}