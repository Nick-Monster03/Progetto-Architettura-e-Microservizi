type UserBalanceRequest {
    .userId: string
}

type UserBalanceResponse {
    .balance: double
}

type UpdateBalanceRequest {
    .userId: string
    .newBalance: double
}

type VehicleInfoRequest {
    .vehicleId: string
}

type VehicleInfoResponse {
    .vehicleId: string
    .stationId: string
    .status: string
    .batteryLevel: int
    .latitude: double
    .longitude: double
    .totalKm: double
    .lastUpdated: string
}

type UpdateVehiclePositionRequest {
    .vehicleId: string
    .latitude: double
    .longitude: double
    .totalKm: double
}

type UpdateVehicleBatteryRequest {
    .vehicleId: string
    .batteryLevel: int
}

type UpdateVehicleStatusRequest {
    .vehicleId: string
    .status: string
}

type CreateAuthorizationRequest {
    .authToken: string
    .userId: string
    .blockedAmount: double
    .isReservation: bool
}

type GetAuthorizationRequest {
    .authToken: string
}

type GetAuthorizationResponse {
    .authToken: string
    .userId: string
    .blockedAmount: double
    .isReservation: bool
    .status: string
    .createdAt: string
}

type UpdateAuthStatusRequest {
    .authToken: string
    .status: string  // ACTIVE, CANCELLED, COMMITTED
}

type InsertTransactionRequest {
    .authToken?: string
    .userId: string
    .transactionType: string  // PRE_AUTH, CANCEL_AUTH, COMMIT_PAYMENT, COMMIT_PENALTY
    .amount: double
    .balanceBefore: double
    .balanceAfter: double
    .description?: string
}

type CreateRentalRequest {
    .userId: string
    .vehicleId: string
    .authToken: string
    .rentalType: string  // IMMEDIATE, RESERVATION
    .startStationId: string
    .startBattery: int
    .startLatitude: double
    .startLongitude: double
}

type CreateRentalResponse {
    .rentalId: int
}

type UpdateRentalRequest {
    .rentalId: int
    .endStationId?: string
    .endTime?: string
    .endBattery?: int
    .endLatitude?: double
    .endLongitude?: double
    .totalKm?: double
    .durationMinutes?: int
    .status?: string  // RESERVED, ACTIVE, COMPLETED, CANCELLED
}

type GetActiveRentalRequest {
    .vehicleId: string
}

type GetActiveRentalResponse {
    .rentalId: int
    .userId: string
    .vehicleId: string
    .rentalType: string
    .startTime: string
    .status: string
}

type CreateInvoiceRequest {
    .rentalId: int
    .userId: string
    .authToken: string
    .subtotal: double
    .penalty: double
    .total: double
    .basePriceTime: double
    .basePriceDistance: double
}

type CreateInvoiceResponse {
    .invoiceId: int
}

type UpdateInvoiceStatusRequest {
    .invoiceId: int
    .paymentStatus: string  
}

interface MyInterface {
    RequestResponse:
        // Users
        getUserBalance(UserBalanceRequest)(UserBalanceResponse),
        updateUserBalance(UpdateBalanceRequest)(int),
        
        // Vehicles
        getVehicleInfo(VehicleInfoRequest)(VehicleInfoResponse),
        updateVehiclePosition(UpdateVehiclePositionRequest)(int),
        updateVehicleBattery(UpdateVehicleBatteryRequest)(int),
        updateVehicleStatus(UpdateVehicleStatusRequest)(int),
        
        // Authorizations
        createAuthorization(CreateAuthorizationRequest)(int),
        getAuthorization(GetAuthorizationRequest)(GetAuthorizationResponse),
        updateAuthStatus(UpdateAuthStatusRequest)(int),
        
        // Transactions
        insertTransaction(InsertTransactionRequest)(int),
        
        // Rentals
        createRental(CreateRentalRequest)(CreateRentalResponse),
        updateRental(UpdateRentalRequest)(int),
        getActiveRental(GetActiveRentalRequest)(GetActiveRentalResponse),
        
        // Invoices
        createInvoice(CreateInvoiceRequest)(CreateInvoiceResponse),
        updateInvoiceStatus(UpdateInvoiceStatusRequest)(int)
}