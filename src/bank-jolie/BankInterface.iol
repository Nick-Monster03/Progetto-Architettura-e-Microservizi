
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

type InsufficientFunds {
    message: string
}

type AccountSuspended {
    message: string
}

type PaymentRefused {
    message: string
}

type CancelAuthRequest {
    token: string
}

interface BankInterface {
    RequestResponse:
        preAuthorize( PreAuthRequest )( PreAuthResponse ) throws InsufficientFunds( InsufficientFunds ) AccountSuspended( AccountSuspended ),
        commitPayment( PaymentRequest )( PaymentResponse ) throws PaymentRefused( PaymentRefused ),
    OneWay:
        cancelAuth( CancelAuthRequest )
}