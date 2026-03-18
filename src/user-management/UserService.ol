include "UserInterface.iol"
include "console.iol"

execution{ concurrent }

inputPort UserPort {
    Location: "socket://0.0.0.0:8005" 
    Protocol: soap {
        .wsdl = "UserService.wsdl"
    }
    Interfaces: UserInterface
}

init {
    println@Console(" User Service avviato sulla porta 8005 (SOAP)")()
    global.users.MarioRossi = "password123"
}

main {
    [ registerUser( request )( response ) {
        // Controlla se l'utente esiste già nella mappa globale
        if ( is_defined( global.users.(request.username) ) ) {
            response.success = false
            response.message = "Errore: Username gia' in uso."
            println@Console("Tentativo di registrazione fallito: utente " + request.username + " gia' esistente.")()
        } else {
            // Salva il nuovo utente e la password
            global.users.(request.username) = request.password
            response.success = true
            response.message = "Registrazione completata con successo."
            println@Console("Nuovo utente registrato: " + request.username)()
        }
    } ]

    [ loginUser( request )( response ) {
        // Controlla se l'utente esiste e se la password coincide
        if ( is_defined( global.users.(request.username) ) && global.users.(request.username) == request.password ) {
            response.success = true
            response.message = "Login effettuato."
            println@Console("Accesso consentito per: " + request.username)()
        } else {
            response.success = false
            response.message = "Username o password errati."
            println@Console("Accesso negato per: " + request.username)()
        }
    } ]
}