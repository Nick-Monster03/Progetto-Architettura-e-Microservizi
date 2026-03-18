include "console.iol"
include "database.iol"
include "string_utils.iol"
include "MyInterface.iol"



execution { concurrent }

inputPort Server {
    Location: "socket://localhost:8000/"
    Protocol: soap
    Interfaces: MyInterface
}

init {
    
    with (connectionInfo) {
        .username = "acme_user";
        .password = "acme_password_2025";
        .host = "postgres";  
        .database = "acme_mobility";
        .driver = "postgresql"
    };

    // with (connectionInfo) {
    //     .username = "camunda";
    //     .password = "camunda";
    //     .host = "localhost";
    //     .database = "acme_mobility"; // "." for memory-only
    //     .port = 5433;
    //     .driver = "postgresql"
    // };
    
    connect@Database(connectionInfo)();
    println@Console("connected")()
}

main {
    
    
    [ getUserBalance(request)(response) {
        query@Database(
            "SELECT balance FROM users WHERE user_id = :userId" {
                .userId = request.userId
            }
        )(sqlResponse);
        
        if (#sqlResponse.row == 1) {
            response.balance = double(sqlResponse.row[0].balance)
        } else {
            update@Database(
                "INSERT INTO users (user_id, balance) VALUES (:userId, 100.00)" {
                    .userId = request.userId
                }
            )(insertResult);
            response.balance = 100.00;
            println@Console("  [DB] Created new user: " + request.userId + " with balance €100")()
        }
    } ]
    
    [ updateUserBalance(request)(result) {
        update@Database(
            "UPDATE users SET balance = :balance, updated_at = CURRENT_TIMESTAMP " +
            "WHERE user_id = :userId" {
                .balance = request.newBalance,
                .userId = request.userId
            }
        )(result)
    } ]
    
    
    
    [ getVehicleInfo(request)(response) {
        query@Database(
            "SELECT * FROM vehicles WHERE vehicle_id = :vehicleId" {
                .vehicleId = request.vehicleId
            }
        )(sqlResponse);
        
        if (#sqlResponse.row == 1) {
            row -> sqlResponse.row[0];
            response.vehicleId = row.vehicle_id;
            response.stationId = row.station_id;
            response.status = row.status;
            response.batteryLevel = int(row.battery_level);
            response.latitude = double(row.latitude);
            response.longitude = double(row.longitude);
            response.totalKm = double(row.total_km);
            response.lastUpdated = row.last_updated
        }
    } ]
    
    [ updateVehiclePosition(request)(result) {
        update@Database(
            "UPDATE vehicles SET " +
            "latitude = :lat, longitude = :lon, total_km = :km, " +
            "last_updated = CURRENT_TIMESTAMP " +
            "WHERE vehicle_id = :vehicleId" {
                .lat = request.latitude,
                .lon = request.longitude,
                .km = request.totalKm,
                .vehicleId = request.vehicleId
            }
        )(result)
    } ]
    
    [ updateVehicleBattery(request)(result) {
        update@Database(
            "UPDATE vehicles SET " +
            "battery_level = :battery, last_updated = CURRENT_TIMESTAMP " +
            "WHERE vehicle_id = :vehicleId" {
                .battery = request.batteryLevel,
                .vehicleId = request.vehicleId
            }
        )(result)
    } ]
    
    [ updateVehicleStatus(request)(result) {
        update@Database(
            "UPDATE vehicles SET " +
            "status = :status, last_updated = CURRENT_TIMESTAMP " +
            "WHERE vehicle_id = :vehicleId" {
                .status = request.status,
                .vehicleId = request.vehicleId
            }
        )(result)
    } ]
    
    
    [ createAuthorization(request)(result) {
        update@Database(
            "INSERT INTO authorizations " +
            "(auth_token, user_id, blocked_amount, is_reservation, status, created_at) " +
            "VALUES (:token, :userId, :amount, :isRes, 'ACTIVE', CURRENT_TIMESTAMP)" {
                .token = request.authToken,
                .userId = request.userId,
                .amount = request.blockedAmount,
                .isRes = request.isReservation
            }
        )(result)
    } ]
    
    [ getAuthorization(request)(response) {
        query@Database(
            "SELECT * FROM authorizations WHERE auth_token = :token" {
                .token = request.authToken
            }
        )(sqlResponse);
        
        if (#sqlResponse.row == 1) {
            row -> sqlResponse.row[0];
            response.authToken = row.auth_token;
            response.userId = row.user_id;
            response.blockedAmount = double(row.blocked_amount);
            response.isReservation = bool(row.is_reservation);
            response.status = row.status;
            response.createdAt = row.created_at
        }
    } ]
    
    [ updateAuthStatus(request)(result) {
        update@Database(
            "UPDATE authorizations SET status = :status " +
            "WHERE auth_token = :token" {
                .status = request.status,
                .token = request.authToken
            }
        )(result)
    } ]
    
    
    [ insertTransaction(request)(result) {
        // Versione semplificata: tutti i campi obbligatori
        query = "INSERT INTO transactions " +
                "(user_id, transaction_type, amount, balance_before, balance_after, created_at";
        
        // Aggiungi campi opzionali
        if (is_defined(request.authToken)) {
            query += ", auth_token"
        };
        if (is_defined(request.description)) {
            query += ", description"
        };
        
        query += ") VALUES (:userId, :txType, :amount, :balBefore, :balAfter, CURRENT_TIMESTAMP";
        
        if (is_defined(request.authToken)) {
            query += ", :token"
        };
        if (is_defined(request.description)) {
            query += ", :desc"
        };
        
        query += ")";
        
        // Costruisci parametri inline
        query.userId = request.userId;
        query.txType = request.transactionType;
        query.amount = request.amount;
        query.balBefore = request.balanceBefore;
        query.balAfter = request.balanceAfter;
        
        if (is_defined(request.authToken)) {
            query.token = request.authToken
        };
        if (is_defined(request.description)) {
            query.desc = request.description
        };
        
        update@Database(query)(result)
    } ]
    
    
    
    [ createRental(request)(response) {
        update@Database(
            "INSERT INTO rentals " +
            "(user_id, vehicle_id, auth_token, rental_type, start_station_id, " +
            "start_battery, start_latitude, start_longitude, start_time, status, created_at) " +
            "VALUES (:userId, :vehicleId, :token, :rentalType, :stationId, " +
            ":battery, :lat, :lon, CURRENT_TIMESTAMP, 'RESERVED', CURRENT_TIMESTAMP) " +
            "RETURNING rental_id" {
                .userId = request.userId,
                .vehicleId = request.vehicleId,
                .token = request.authToken,
                .rentalType = request.rentalType,
                .stationId = request.startStationId,
                .battery = request.startBattery,
                .lat = request.startLatitude,
                .lon = request.startLongitude
            }
        )(sqlResponse);
        
        response.rentalId = int(sqlResponse)
    } ]
    
    [ updateRental(request)(result) {
        // Build dynamic UPDATE query
        query = "UPDATE rentals SET updated_at = CURRENT_TIMESTAMP";
        query.rentalId = request.rentalId;
        
        if (is_defined(request.endStationId)) {
            query += ", end_station_id = :endStation";
            query.endStation = request.endStationId
        };
        if (is_defined(request.endTime)) {
            query += ", end_time = CURRENT_TIMESTAMP"
        };
        if (is_defined(request.endBattery)) {
            query += ", end_battery = :endBattery";
            query.endBattery = request.endBattery
        };
        if (is_defined(request.endLatitude)) {
            query += ", end_latitude = :endLat, end_longitude = :endLon";
            query.endLat = request.endLatitude;
            query.endLon = request.endLongitude
        };
        if (is_defined(request.totalKm)) {
            query += ", total_km = :km";
            query.km = request.totalKm
        };
        if (is_defined(request.durationMinutes)) {
            query += ", duration_minutes = :duration";
            query.duration = request.durationMinutes
        };
        if (is_defined(request.status)) {
            query += ", status = :status";
            query.status = request.status
        };
        
        query += " WHERE rental_id = :rentalId";
        
        update@Database(query)(result)
    } ]
    
    [ getActiveRental(request)(response) {
        query@Database(
            "SELECT rental_id, user_id, vehicle_id, rental_type, start_time, status " +
            "FROM rentals " +
            "WHERE vehicle_id = :vehicleId AND status IN ('RESERVED', 'ACTIVE') " +
            "ORDER BY created_at DESC LIMIT 1" {
                .vehicleId = request.vehicleId
            }
        )(sqlResponse);
        
        if (#sqlResponse.row == 1) {
            row -> sqlResponse.row[0];
            response.rentalId = int(row.rental_id);
            response.userId = row.user_id;
            response.vehicleId = row.vehicle_id;
            response.rentalType = row.rental_type;
            response.startTime = row.start_time;
            response.status = row.status
        }
    } ]
    
    
    
    [ createInvoice(request)(response) {
        update@Database(
            "INSERT INTO invoices " +
            "(rental_id, user_id, auth_token, subtotal, penalty, total, " +
            "base_price_time, base_price_distance, payment_status, created_at) " +
            "VALUES (:rentalId, :userId, :token, :subtotal, :penalty, :total, " +
            ":priceTime, :priceDistance, 'PENDING', CURRENT_TIMESTAMP) " +
            "RETURNING invoice_id" {
                .rentalId = request.rentalId,
                .userId = request.userId,
                .token = request.authToken,
                .subtotal = request.subtotal,
                .penalty = request.penalty,
                .total = request.total,
                .priceTime = request.basePriceTime,
                .priceDistance = request.basePriceDistance
            }
        )(sqlResponse);
        
        response.invoiceId = int(sqlResponse)
    } ]
    
    [ updateInvoiceStatus(request)(result) {
        q = "UPDATE invoices SET payment_status = :status";
        q.status = request.paymentStatus;
        q.invoiceId = request.invoiceId;
        
        if (request.paymentStatus == "PAID") {
            q += ", paid_at = CURRENT_TIMESTAMP"
        };
        
        q += " WHERE invoice_id = :invoiceId";
        
        update@Database(q)(result)
    } ]
}


