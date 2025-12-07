type PreAuthRequest: void {
    .userId: string     
    .veichleId: string
}

type PreAuthResponse: void {
    .token: string      
}

type CommitRequest: void {
    .token: string      
    .finalAmount: double 
    .veichleId: string
    .userId: string
}
interface BankInterface {
    RequestResponse:
        preAuthorize( PreAuthRequest )( PreAuthResponse ),
        commitPayment( CommitRequest )( void )
}


