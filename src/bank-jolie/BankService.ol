include "console.iol"
include "database.iol"
include "string_utils.iol"
include "time.iol"
include "BankInterface.iol"

// ============================================================
// STATUS ENUM - authorizations.status
// ACTIVE    → Pre-auth attiva, noleggio in corso
// CANCELLED → Annullato, cauzione restituita
// COMMITTED → Completato, pagamento/penale eseguito
// ============================================================

execution { concurrent }

inputPort BankPort {
    Location: "socket://0.0.0.0:8008"
    Protocol: soap {
        .wsdl = "BankService.wsdl"
    }
    Interfaces: BankInterface
}

cset {
    authToken: PreAuthorizeResponse.authToken
               CommitPaymentRequest.authToken
               CommitPenaltyRequest.authToken
               CancelAuthRequest.authToken
}

init {
    with (connectionInfo) {
        .username = "camunda";
        .password = "camunda";
        .host = "postgres";
        .port = 5432;
        .database = "camunda";
        .driver = "postgresql"
    };
    connect@Database(connectionInfo)();

    global.transactionCounter = 0;
    println@Console("Bank Service avviato (Porta 8008)")();
    println@Console("Connected to camunda DB")()
}

main {

    preAuthorize(request)(response) {

        userId = request.userId;
        amount = double(request.amount);
        session.userId = userId;

        println@Console("\n[BANK] === PRE-AUTHORIZE (" + userId + ") ===")();

        synchronized(balanceLock) {

            query@Database(
                "SELECT balance FROM user_bank WHERE user_id = '" + userId + "'"
            )(balRes);

            if (#balRes.row == 0) {
                response.success      = false;
                response.errorCode    = "USER_NOT_FOUND";
                response.errorMessage = "Utente non trovato";
                println@Console("[BANK] X User not found: " + userId)()
            } else {
                currentBalance = double(balRes.row[0].balance);
                println@Console("[BANK] Current balance: E" + currentBalance)();

                if (currentBalance >= amount) {

                    getCurrentTimeMillis@Time()(timestamp);
                    authToken = "TOK_" + userId + "_" + timestamp;

                    csets.authToken       = authToken;
                    session.authToken     = authToken;
                    session.blockedAmount = amount;

                    // 1. Scala saldo
                    newBalance = currentBalance - amount;
                    update@Database(
                        "UPDATE user_bank SET balance = " + newBalance + ", updated_at = CURRENT_TIMESTAMP " +
                        "WHERE user_id = '" + userId + "'"
                    )(ur);

                    // 2. Crea autorizzazione
                    update@Database(
                        "INSERT INTO authorizations (auth_token, user_id, is_reservation, status, expires_at) " +
                        "VALUES ('" + authToken + "', '" + userId + "', " + request.isRiservation + ", 'ACTIVE', " +
                        "CURRENT_TIMESTAMP + INTERVAL '30 minutes')"
                    )(ar);

                    // 3. Registra transazione
                    negAmount = amount * (-1);
                    update@Database(
                        "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                        "balance_before, balance_after, description, created_at) " +
                        "VALUES ('" + authToken + "', '" + userId + "', 'PRE_AUTH', " + negAmount + ", " +
                        currentBalance + ", " + newBalance + ", 'Pre-authorization blocked', CURRENT_TIMESTAMP)"
                    )(tr);

                    response.success       = true;
                    response.authToken     = authToken;
                    response.blockedAmount = amount;
                    response.errorCode     = "";
                    response.errorMessage  = "";

                    println@Console("[BANK] Token:   " + authToken)();
                    println@Console("[BANK]   Blocked: E" + amount)();
                    println@Console("[BANK]   Balance: E" + currentBalance + " -> E" + newBalance)()

                } else {
                    response.success      = false;
                    response.errorCode    = "INSUFFICIENT_FUNDS";
                    response.errorMessage = "Saldo insufficiente (disponibile: E" + currentBalance + ")";
                    println@Console("[BANK] X Insufficient funds: E" + currentBalance)()
                }
            }
        }
    };

    if (response.success) {
        undef(response);

        [ cancelAuth(request) ] {
            println@Console("\n[BANK] === CANCEL AUTH (" + session.userId + ") ===")();

            synchronized(balanceLock) {

                query@Database(
                    "SELECT balance FROM user_bank WHERE user_id = '" + session.userId + "'"
                )(balRes);
                currentBalance = double(balRes.row[0].balance);

                if (request.isExpired) {
                    // Scaduta → trattieni cauzione
                    update@Database(
                        "UPDATE authorizations SET status = 'COMMITTED' " +
                        "WHERE auth_token = '" + session.authToken + "'"
                    )(sr);

                    negAmount = session.blockedAmount * (-1);
                    update@Database(
                        "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                        "balance_before, balance_after, description, created_at) " +
                        "VALUES ('" + session.authToken + "', '" + session.userId + "', 'COMMIT_PENALTY', " +
                        negAmount + ", " + currentBalance + ", " + currentBalance + ", " +
                        "'Expired reservation - deposit retained', CURRENT_TIMESTAMP)"
                    )(tr);

                    println@Console("[BANK] Expired: deposit retained (E" + session.blockedAmount + ")")()

                } else {
                    // Rimborso totale
                    newBalance = currentBalance + session.blockedAmount;

                    update@Database(
                        "UPDATE user_bank SET balance = " + newBalance + ", updated_at = CURRENT_TIMESTAMP " +
                        "WHERE user_id = '" + session.userId + "'"
                    )(ur);

                    update@Database(
                        "UPDATE authorizations SET status = 'CANCELLED' " +
                        "WHERE auth_token = '" + session.authToken + "'"
                    )(sr);

                    update@Database(
                        "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                        "balance_before, balance_after, description, created_at) " +
                        "VALUES ('" + session.authToken + "', '" + session.userId + "', 'CANCEL_AUTH', " +
                        session.blockedAmount + ", " + currentBalance + ", " + newBalance + ", " +
                        "'Authorization cancelled - full refund', CURRENT_TIMESTAMP)"
                    )(tr);

                    println@Console("[BANK] Refunded E" + session.blockedAmount + ". Balance: E" + currentBalance + " -> E" + newBalance)()
                }
            };
            sleep@Time(2000)()
        }

        [ commitPayment(request)(response) {
            println@Console("\n[BANK] === COMMIT PAYMENT (" + session.userId + ") ===")();

            finalAmount = double(request.finalAmount);
            println@Console("[BANK] Final amount: E" + finalAmount)();

            synchronized(balanceLock) {

                query@Database(
                    "SELECT balance FROM user_bank WHERE user_id = '" + session.userId + "'"
                )(balRes);
                currentBalance = double(balRes.row[0].balance);

                if (finalAmount <= session.blockedAmount) {
                    // Costo < cauzione → rimborso differenza
                    refund     = session.blockedAmount - finalAmount;
                    newBalance = currentBalance + refund;

                    update@Database(
                        "UPDATE user_bank SET balance = " + newBalance + ", updated_at = CURRENT_TIMESTAMP " +
                        "WHERE user_id = '" + session.userId + "'"
                    )(ur);

                    update@Database(
                        "UPDATE authorizations SET status = 'COMMITTED' " +
                        "WHERE auth_token = '" + session.authToken + "'"
                    )(sr);

                    negAmount = finalAmount * (-1);
                    update@Database(
                        "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                        "balance_before, balance_after, description, created_at) " +
                        "VALUES ('" + session.authToken + "', '" + session.userId + "', 'COMMIT_PAYMENT', " +
                        negAmount + ", " + currentBalance + ", " + newBalance + ", " +
                        "'Payment - refund " + refund + "', CURRENT_TIMESTAMP)"
                    )(tr);

                    response.success       = true;
                    response.chargedAmount = finalAmount;
                    response.receiptId     = "RCP_PAY_" + session.userId;

                    println@Console("[BANK] Paid: E" + finalAmount + " | Refund: E" + refund)();
                    println@Console("[BANK]   Balance: E" + currentBalance + " -> E" + newBalance)()

                } else {
                    // Costo > cauzione → addebito extra
                    extra = finalAmount - session.blockedAmount;

                    if (currentBalance >= extra) {
                        newBalance = currentBalance - extra;

                        update@Database(
                            "UPDATE user_bank SET balance = " + newBalance + ", updated_at = CURRENT_TIMESTAMP " +
                            "WHERE user_id = '" + session.userId + "'"
                        )(ur);

                        update@Database(
                            "UPDATE authorizations SET status = 'COMMITTED' " +
                            "WHERE auth_token = '" + session.authToken + "'"
                        )(sr);

                        negAmount = finalAmount * (-1);
                        update@Database(
                            "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                            "balance_before, balance_after, description, created_at) " +
                            "VALUES ('" + session.authToken + "', '" + session.userId + "', 'COMMIT_PAYMENT', " +
                            negAmount + ", " + currentBalance + ", " + newBalance + ", " +
                            "'Payment - extra " + extra + "', CURRENT_TIMESTAMP)"
                        )(tr);

                        response.success       = true;
                        response.chargedAmount = finalAmount;
                        response.receiptId     = "RCP_PAY_" + session.userId;

                        println@Console("[BANK] Paid: E" + finalAmount + " | Extra: E" + extra)();
                        println@Console("[BANK]   Balance: E" + currentBalance + " -> E" + newBalance)()

                    } else {
                        response.success      = false;
                        response.errorCode    = "INSUFFICIENT_FUNDS";
                        response.errorMessage = "Fondi insufficienti per saldo finale";
                        println@Console("[BANK] X Insolvency: need E" + extra + ", have E" + currentBalance)()
                    }
                }
            }
        } ]

        [ commitPenalty(request)(response) {
            println@Console("\n[BANK] === COMMIT PENALTY (" + session.userId + ") ===")();

            penaltyAmount = double(request.penaltyAmount);
            println@Console("[BANK] Penalty: E" + penaltyAmount)();

            synchronized(balanceLock) {

                query@Database(
                    "SELECT balance FROM user_bank WHERE user_id = '" + session.userId + "'"
                )(balRes);
                currentBalance = double(balRes.row[0].balance);

                if (penaltyAmount < session.blockedAmount) {
                    refund     = session.blockedAmount - penaltyAmount;
                    newBalance = currentBalance + refund;

                    update@Database(
                        "UPDATE user_bank SET balance = " + newBalance + ", updated_at = CURRENT_TIMESTAMP " +
                        "WHERE user_id = '" + session.userId + "'"
                    )(ur);

                    println@Console("[BANK] Partial penalty: E" + penaltyAmount + " | Refund: E" + refund)()
                } else {
                    newBalance = currentBalance;
                    println@Console("[BANK] Full deposit retained: E" + session.blockedAmount)()
                };

                update@Database(
                    "UPDATE authorizations SET status = 'COMMITTED' " +
                    "WHERE auth_token = '" + session.authToken + "'"
                )(sr);

                negAmount = penaltyAmount * (-1);
                update@Database(
                    "INSERT INTO transactions (auth_token, user_id, transaction_type, amount, " +
                    "balance_before, balance_after, description, created_at) " +
                    "VALUES ('" + session.authToken + "', '" + session.userId + "', 'COMMIT_PENALTY', " +
                    negAmount + ", " + currentBalance + ", " + newBalance + ", " +
                    "'Cancellation penalty', CURRENT_TIMESTAMP)"
                )(tr);

                response.success       = true;
                response.chargedAmount = penaltyAmount;
                getCurrentTimeMillis@Time()(ts);
                response.receiptId     = "RCP_PEN_" + session.userId + "_" + ts;

                println@Console("[BANK] Balance: E" + currentBalance + " -> E" + newBalance)()
            }
        } ]
    };

    println@Console("[BANK] Session closed for " + session.userId + "\n")()
}
