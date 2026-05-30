include "console.iol"
include "database.iol"
include "MyInterface.iol"

// ============================================================
// DatabaseService - Servizio standalone su porta 9000
// BankService lo contatta via outputPort
// ============================================================

service DatabaseService {

    execution { concurrent }

    inputPort DatabaseServicePort {
        Location: "socket://0.0.0.0:9000"
        Protocol: sodep
        Interfaces: MyInterface
    }

    init {
        with (connectionInfo) {
            .username = "acme_user";
            .password = "acme_password_2025";
            .host = "localhost";
            .port = 5433;
            .database = "acme_mobility";
            .driver = "postgresql"
        };
        connect@Database(connectionInfo)();
        println@Console("[DB] connected to acme_mobility on port 9000")()
    }

    main {

        [ getUserBalance(request)(response) {
            query@Database(
                "SELECT balance FROM user_bank WHERE user_id = :userId" {
                    .userId = request.userId
                }
            )(sqlResponse);
            if (#sqlResponse.row == 1) {
                response.balance = double(sqlResponse.row[0].balance)
            } else {
                response.balance = 0.0
            }
        } ]

        [ updateUserBalance(request)(result) {
            update@Database(
                "UPDATE user_bank SET balance = :balance, updated_at = CURRENT_TIMESTAMP " +
                "WHERE user_id = :userId" {
                    .balance = request.newBalance,
                    .userId  = request.userId
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
                response.vehicleId    = row.vehicle_id;
                response.stationId    = row.station_id;
                response.status       = row.status;
                response.batteryLevel = int(row.battery_level);
                response.lastUpdated  = row.last_updated
            }
        } ]

        [ updateVehicleBattery(request)(result) {
            update@Database(
                "UPDATE vehicles SET battery_level = :battery, last_updated = CURRENT_TIMESTAMP " +
                "WHERE vehicle_id = :vehicleId" {
                    .battery   = request.batteryLevel,
                    .vehicleId = request.vehicleId
                }
            )(result)
        } ]

        [ updateVehicleStatus(request)(result) {
            update@Database(
                "UPDATE vehicles SET status = :status, last_updated = CURRENT_TIMESTAMP " +
                "WHERE vehicle_id = :vehicleId" {
                    .status    = request.status,
                    .vehicleId = request.vehicleId
                }
            )(result)
        } ]

        [ createAuthorization(request)(result) {
            update@Database(
                "INSERT INTO authorizations (auth_token, user_id, is_reservation, status) " +
                "VALUES (:token, :userId, :isRes, 'ACTIVE')" {
                    .token  = request.authToken,
                    .userId = request.userId,
                    .isRes  = request.isReservation
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
                response.authToken     = row.auth_token;
                response.userId        = row.user_id;
                response.isReservation = bool(row.is_reservation);
                response.status        = row.status;
                response.createdAt     = row.created_at
            }
        } ]

        [ updateAuthStatus(request)(result) {
            update@Database(
                "UPDATE authorizations SET status = :status WHERE auth_token = :token" {
                    .status = request.status,
                    .token  = request.authToken
                }
            )(result)
        } ]

        [ insertTransaction(request)(result) {
            q = "INSERT INTO transactions " +
                "(user_id, transaction_type, amount, balance_before, balance_after, created_at";
            if (is_defined(request.authToken)) {
                q += ", auth_token"
            };
            if (is_defined(request.description)) {
                q += ", description"
            };
            q += ") VALUES (:userId, :txType, :amount, :balBefore, :balAfter, CURRENT_TIMESTAMP";
            if (is_defined(request.authToken)) {
                q += ", :token"
            };
            if (is_defined(request.description)) {
                q += ", :desc"
            };
            q += ")";
            q.userId    = request.userId;
            q.txType    = request.transactionType;
            q.amount    = request.amount;
            q.balBefore = request.balanceBefore;
            q.balAfter  = request.balanceAfter;
            if (is_defined(request.authToken)) {
                q.token = request.authToken
            };
            if (is_defined(request.description)) {
                q.desc = request.description
            };
            update@Database(q)(result)
        } ]

        [ createRental(request)(response) {
            update@Database(
                "INSERT INTO rentals " +
                "(user_id, vehicle_id, auth_token, rental_type, start_station_id, " +
                "start_battery, start_latitude, start_longitude, start_time, status, created_at) " +
                "VALUES (:userId, :vehicleId, :token, :rentalType, :stationId, " +
                ":battery, :lat, :lon, CURRENT_TIMESTAMP, 'RESERVED', CURRENT_TIMESTAMP)" {
                    .userId     = request.userId,
                    .vehicleId  = request.vehicleId,
                    .token      = request.authToken,
                    .rentalType = request.rentalType,
                    .stationId  = request.startStationId,
                    .battery    = request.startBattery,
                    .lat        = request.startLatitude,
                    .lon        = request.startLongitude
                }
            )(insertResult);
            query@Database(
                "SELECT rental_id FROM rentals WHERE vehicle_id = :vehicleId ORDER BY created_at DESC LIMIT 1" {
                    .vehicleId = request.vehicleId
                }
            )(sqlResponse);
            response.rentalId = int(sqlResponse.row[0].rental_id)
        } ]

        [ updateRental(request)(result) {
            q = "UPDATE rentals SET updated_at = CURRENT_TIMESTAMP";
            q.rentalId = request.rentalId;
            if (is_defined(request.endStationId)) {
                q += ", end_station_id = :endStation";
                q.endStation = request.endStationId
            };
            if (is_defined(request.endTime)) {
                if (request.endTime == true) {
                    q += ", end_time = CURRENT_TIMESTAMP"
                }
            };
            if (is_defined(request.endBattery)) {
                q += ", end_battery = :endBattery";
                q.endBattery = request.endBattery
            };
            if (is_defined(request.endLatitude) && is_defined(request.endLongitude)) {
                q += ", end_latitude = :endLat, end_longitude = :endLon";
                q.endLat = request.endLatitude;
                q.endLon = request.endLongitude
            };
            if (is_defined(request.totalKm)) {
                q += ", total_km = :km";
                q.km = request.totalKm
            };
            if (is_defined(request.status)) {
                q += ", status = :status";
                q.status = request.status
            };
            q += " WHERE rental_id = :rentalId";
            update@Database(q)(result)
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
                response.rentalId   = int(row.rental_id);
                response.userId     = row.user_id;
                response.vehicleId  = row.vehicle_id;
                response.rentalType = row.rental_type;
                response.startTime  = row.start_time;
                response.status     = row.status
            }
        } ]

        [ createInvoice(request)(response) {
            update@Database(
                "INSERT INTO invoices (rental_id, user_id, subtotal, penalty, payment_status, created_at) " +
                "VALUES (:rentalId, :userId, :subtotal, :penalty, 'PENDING', CURRENT_TIMESTAMP)" {
                    .rentalId = request.rentalId,
                    .userId   = request.userId,
                    .subtotal = request.subtotal,
                    .penalty  = request.penalty
                }
            )(insertResult);
            query@Database(
                "SELECT invoice_id FROM invoices WHERE rental_id = :rentalId ORDER BY created_at DESC LIMIT 1" {
                    .rentalId = request.rentalId
                }
            )(sqlResponse);
            response.invoiceId = int(sqlResponse.row[0].invoice_id)
        } ]

        [ updateInvoiceStatus(request)(result) {
            q = "UPDATE invoices SET payment_status = :status WHERE invoice_id = :invoiceId";
            q.status    = request.paymentStatus;
            q.invoiceId = request.invoiceId;
            update@Database(q)(result)
        } ]
    }
}
