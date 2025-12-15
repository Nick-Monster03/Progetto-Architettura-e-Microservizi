
type PreAuthRequest {
    clientName: string
    cardNumber: string
}

type PreAuthResponse {
    paymentToken: string 
    success: bool
    message: string
}

type PaymentRequest {
    paymentToken: string 
    amount: double
}

type PaymentResponse {
    txId: string
    success: bool
    message: string
}

interface BankInterface {
    RequestResponse:
        preAuthorize( PreAuthRequest )( PreAuthResponse ),
        commitPayment( PaymentRequest )( PaymentResponse )
}