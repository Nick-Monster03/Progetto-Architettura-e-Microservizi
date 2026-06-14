include "UserInterface.iol"
include "console.iol"
include "database.iol"

execution{ concurrent }

inputPort UserPort {
    Location: "socket://0.0.0.0:8005" 
    Protocol: soap {
        .wsdl = "UserService.wsdl"
    }
    Interfaces: UserInterface
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
    println@Console(" User Service avviato sulla porta 8005 (SOAP)")();
    println@Console("Connected to camunda DB")()
    // global.users.MarioRossi = "password123"
}

main {
    [ registerUser( request )( response ) {
        
        synchronized(userLock) {
            
            query@Database(
                "SELECT * FROM users WHERE user_id = '" + request.username + "'"
            )(users);

            if ( #users.row > 0 ) {
                response.success = false;
                response.message = "Errore: Username gia' in uso.";
                println@Console("Tentativo di registrazione fallito: utente " + request.username + " gia' esistente.")()
            } else {
                userId = request.username;
                password = request.password;
                update@Database(
                    "INSERT INTO users (user_id, password) " +
                    "VALUES ('" + userId + "', '" + password + "')"
                )(resUser);
                
                //Ad ogni nuovo utente viene regalato un bonus di benvenuto di 10 euro
                update@Database(
                    "INSERT INTO user_bank (user_id, balance) " +
                    "VALUES ('" + userId + "', 10.00)"
                )(resBank);

                response.success = true;
                response.message = "Registrazione effettuata con success";
                println@Console("Nuovo utente registrato: " + userId)()
            }

        }
    } ]

    [ loginUser( request )( response ) {
       
        synchronized(userLock) {
            query@Database(
                "SELECT * FROM users WHERE user_id = '" + request.username + "' AND password = '" + request.password + "'"
            )(users);

            if ( #users.row > 0 ) {
                response.success = true;
                response.message = "Login effettuato con successo.";
                println@Console("Utente " + request.username + " ha effettuato il login.")()
            } else {
                response.success = false;
                response.message = "Errore: Username o password errati.";
                println@Console("Tentativo di login fallito per utente " + request.username)()
            }
        }
    } ]
}