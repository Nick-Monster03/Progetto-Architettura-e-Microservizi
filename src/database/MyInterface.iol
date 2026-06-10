// ============================================================
// MyInterface.iol - Interfaccia per DatabaseService
// Allineata allo schema reale del database acme_mobility
// ============================================================

// ==================== USERS / USER_BANK ====================

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

// ==================== VEHICLES ====================
// Nota: lat/lon/km sono in tracking_veichle, non in vehicles

type VehicleInfoRequest {
    .vehicleId: string
}

type VehicleInfoResponse {
    .vehicleId: string
    .stationId: string
    .status: string        // AVAILABLE, RESERVED, UNLOCKED, IN_USE, BROKEN, CHARGING
    .batteryLevel: int
    .lastUpdated: string
}

type UpdateVehicleBatteryRequest {
    .vehicleId: string
    .batteryLevel: int
}

type UpdateVehicleStatusRequest {
    .vehicleId: string
    .status: string        // AVAILABLE, RESERVED, UNLOCKED, IN_USE, BROKEN, CHARGING
}

// ==================== AUTHORIZATIONS ====================
// Nota: blocked_amount rimosso (sempre €10)

type CreateAuthorizationRequest {
    .authToken: string
    .userId: string
    .isReservation: bool
    // status DEFAULT = 'ACTIVE' impostato dal DB
}

type GetAuthorizationRequest {
    .authToken: string
}

type GetAuthorizationResponse {
    .authToken: string
    .userId: string
    .isReservation: bool
    .status: string        // ACTIVE, CANCELLED, COMMITTED
    .createdAt: string
}

type UpdateAuthStatusRequest {
    .authToken: string
    .status: string        // ACTIVE, CANCELLED, COMMITTED
}

// ==================== TRANSACTIONS ====================

type InsertTransactionRequest {
    .userId: string
    .transactionType: string  // PRE_AUTH, CANCEL_AUTH, COMMIT_PAYMENT, COMMIT_PENALTY
    .amount: double
    .balanceBefore: double
    .balanceAfter: double
    .authToken?: string
    .description?: string
}

// ==================== RENTALS ====================

type CreateRentalRequest {
    .userId: string
    .vehicleId: string
    .authToken: string
    .rentalType: string        // IMMEDIATE, RESERVATION
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
    .endTime?: bool            // se true imposta CURRENT_TIMESTAMP
    .endBattery?: int
    .endLatitude?: double
    .endLongitude?: double
    .totalKm?: double
    .status?: string           // RESERVED, ACTIVE, COMPLETED, CANCELLED
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

// ==================== INVOICES ====================
// Nota: tabella ha solo (invoice_id, rental_id, user_id, subtotal, penalty, payment_status, created_at)

type CreateInvoiceRequest {
    .rentalId: int
    .userId: string
    .subtotal: double
    .penalty: double
}

type CreateInvoiceResponse {
    .invoiceId: int
}

type UpdateInvoiceStatusRequest {
    .invoiceId: int
    .paymentStatus: string     // PENDING, PAID, FAILED
}

// ============================================================
// INTERFACCIA PRINCIPALE
// ============================================================

interface MyInterface {
    RequestResponse:
        // user_bank
        getUserBalance(UserBalanceRequest)(UserBalanceResponse),
        updateUserBalance(UpdateBalanceRequest)(int),

        // vehicles
        getVehicleInfo(VehicleInfoRequest)(VehicleInfoResponse),
        updateVehicleBattery(UpdateVehicleBatteryRequest)(int),
        updateVehicleStatus(UpdateVehicleStatusRequest)(int),

        // authorizations
        createAuthorization(CreateAuthorizationRequest)(int),
        getAuthorization(GetAuthorizationRequest)(GetAuthorizationResponse),
        updateAuthStatus(UpdateAuthStatusRequest)(int),

        // transactions
        insertTransaction(InsertTransactionRequest)(int),

        // rentals
        createRental(CreateRentalRequest)(CreateRentalResponse),
        updateRental(UpdateRentalRequest)(int),
        getActiveRental(GetActiveRentalRequest)(GetActiveRentalResponse),

        // invoices
        createInvoice(CreateInvoiceRequest)(CreateInvoiceResponse),
        updateInvoiceStatus(UpdateInvoiceStatusRequest)(int)
}
