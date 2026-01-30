include "FleetInterface.iol"
include "../tracking/TrackingInterface.iol"
include "../battery/BatteryInterface.iol"
include "../../service-utils/CostCalculatorInterface.iol"
include "../../bank-jolie/BankInterface.iol"
from time import Time
from console import Console

service FleetGateway {
    execution: concurrent

    // --- INTERFACCIA ESTERNA (REST/JSON per il Client) ---
    // Manteniamo la configurazione DevMatte per compatibilità Frontend/Docker
    inputPort FleetPublicPort {
        Location: "socket://0.0.0.0:8082"    
        Protocol: http { 
            .format = "json";
            .osc.startTracking.method = "post";
            .osc.registerUser.method = "post";
            .osc.stopTracking.method = "post";
            .osc.bookVehicle.method = "post";
            .osc.getStatus.method = "get";
            .osc.getMap.method = "get";
            
            // Gestione CORS necessaria per il browser
            .osc.handleOptions.method = "options";
            .default = "handleOptions";
            .response.headers.("Access-Control-Allow-Origin") = "*";
            .response.headers.("Access-Control-Allow-Methods") = "GET, POST, OPTIONS, PUT, DELETE";
            .response.headers.("Access-Control-Allow-Headers") = "Content-Type"
        }
        Interfaces: FleetInterface
    }

    // --- SERVIZI INTERNI (SOAP per Backend SOA) ---
    
    // Tracking Service
    outputPort Tracking {
        // Usa il nome del servizio Docker (da DevMatte) ma protocollo SOAP (da develope/traccia)
        Location: "socket://tracking-service:8084" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: TrackingInterface
    }

    // Battery Service
    outputPort Battery {
        Location: "socket://battery-service:8085" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: BatteryInterface
    }

    // Calculator Service (aggiunto da develope)
    outputPort CalculatorPort {
        // Corretto localhost -> calculator-service per Docker
        Location: "socket://calculator-service:8089" 
        Protocol: soap { .dropRootValue = true }
        Interfaces: CostCalculatorInterface
    }

    // Bank Service (aggiunto per coreografia)
    outputPort Bank {
        Location: "socket://bank-service:8008"
        Protocol: soap { .dropRootValue = true }
        Interfaces: BankInterface
    }

    embed Console as Console

    main {
        
        // Avvia il monitoraggio
        [ startTracking( request )( response ) {
            // Validazione (DevMatte)
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Start Tracking: " + request.vehicleId)();
                
                // Logica differenziata: Noleggio Immediato vs Pickup da Prenotazione
                shouldAuthorize = true;
                if ( is_defined(request.isReservationPickup) && request.isReservationPickup == true ) {
                    // Caso B1: Ritiro Veicolo (Pickup) - La pre-auth è già stata fatta in bookVehicle
                    println@Console("[GATEWAY] Pickup da prenotazione: salto pre-auth.")();
                    
                    // Verifica se esiste un token (sicurezza)
                    synchronized( gatewayLock ) {
                        if ( !is_defined(global.payment_tokens.(request.vehicleId)) ) {
                            // Anomalia: Prenotazione dichiarata ma nessun token trovato
                            shouldAuthorize = true; // Fallback: rifacciamo l'auth per sicurezza
                            println@Console("[GATEWAY] WARN: Token non trovato per pickup. Eseguo nuova auth.")()
                        } else {
                            shouldAuthorize = false;
                            response.success = true // Procediamo diretti
                        }
                    }
                };

                if ( shouldAuthorize ) {
                    // Caso A: Noleggio Immediato - Serve Pre-autorizzazione
                    scope( bankScope ) {
                        install( InsufficientFunds => 
                            response.success = false;
                            response.message = "Fondi insufficienti per il noleggio.";
                            println@Console("[GATEWAY] Pre-auth fallita: Fondi insufficienti")()
                        );
                        install( AccountSuspended =>
                            response.success = false;
                            response.message = "Account sospeso.";
                            println@Console("[GATEWAY] Pre-auth fallita: Account sospeso")()
                        );

                        preAuthorize@Bank( { 
                            .clientName = request.clientName, 
                            .cardNumber = request.cardNumber 
                        } )( bankResponse );

                        // Salviamo il token di pagamento per la chiusura
                        synchronized( gatewayLock ) {
                            global.payment_tokens.(request.vehicleId) = bankResponse.paymentToken
                        }
                    }
                };

                if ( !is_defined(response.success) || response.success == true ) { // Se non fallito sopra
                    // Logica SOA
                    setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RENTED" } )();
                    
                    // Salvataggio tempo inizio (develope)
                    if ( !is_defined(request.time) ) {
                        request.time = new
                    };
                    synchronized( gatewayLock ) {
                        global.starting_times.(request.vehicleId) = request.time
                    };

                    response.success = true;
                    response.message = "Monitoraggio avviato."
                }
            } else {
                println@Console("[GATEWAY] Errore startTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio."
            }
        } ]

        // Termina il noleggio
        [ stopTracking( request )( response ) {
            // Validazione (DevMatte)
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Stop Tracking: " + request.vehicleId)();
                
                // 1. Aggiornamento stato
                setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "AVAILABLE" } )();
                
                // 2. Recupero dati per calcolo
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                // 3. Calcolo Costo (Logica develope)
                totalCost = 0.0;
                costMsg = "";
                
                synchronized( gatewayLock ) {
                    if ( is_defined( global.starting_times.(request.vehicleId) ) ) {
                        start_time = global.starting_times.(request.vehicleId);
                        // Se request.time manca, usa timestamp attuale fittizio o ricevuto
                        if ( !is_defined(request.time) ) request.time = start_time + 600000; // fallback 10 min

                        // Calcolo minuti (ms / 60000)
                        minutes = (request.time - start_time) / 60000;
                        if ( minutes < 1 ) minutes = 1; // Minimo 1 minuto

                        calculateCost@CalculatorPort( { .minutes = minutes, .batteryLevel = batt } )( costResponse );
                        totalCost = costResponse.totalCost;
                        costMsg = " Costo: " + totalCost + " EUR"
                    }
                };

                // 4. Pagamento Finale (Coreografia)
                scope( paymentScope ) {
                    install( PaymentRefused => 
                        response.success = false;
                        response.message = "Noleggio chiuso ma Pagamento Rifiutato: " + PaymentRefused.message;
                        println@Console("[GATEWAY] Pagamento fallito: " + PaymentRefused.message)()
                    );

                    // Recupera token salvato
                    token = "";
                    synchronized( gatewayLock ) {
                        if ( is_defined( global.payment_tokens.(request.vehicleId) ) ) {
                            token = global.payment_tokens.(request.vehicleId)
                        }
                    };

                    if ( token != "" ) {
                        commitPayment@Bank( { 
                            .paymentToken = token, 
                            .amount = totalCost 
                        } )( payResponse );
                        
                        response.success = true;
                        response.message = "Noleggio terminato. Bat: " + batt + "%." + costMsg + ". Transazione: " + payResponse.txId
                    } else {
                        // Fallback se non c'è token (es. riavvio server)
                        response.success = true;
                        response.message = "Noleggio terminato (No Payment Token found). Bat: " + batt + "%." + costMsg
                    }
                }

            } else {
                println@Console("[GATEWAY] Errore stopTracking: vehicleId mancante!")();
                response.success = false;
                response.message = "Errore: Parametro 'vehicleId' obbligatorio per terminare il noleggio."
            }
        } ]

        // Ottieni stato veicolo
        [ getStatus( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                // Chiamate SOAP
                getInfo@Tracking( { .vehicleId = request.vehicleId } )( info );
                getBattery@Battery( { .vehicleId = request.vehicleId } )( batt );

                response.vehicleId = request.vehicleId;
                response.status = info.status;
                response.latitude = info.location.latitude;
                response.longitude = info.location.longitude;
                response.batteryLevel = batt
            } else {
                println@Console("[GATEWAY] Errore getStatus: vehicleId mancante!")();
                response.vehicleId = "UNKNOWN";
                response.status = "ERROR_MISSING_ID";
                response.batteryLevel = -1 
            }
        } ]

        // Operazioni standard (Mantenute da DevMatte)
        [ bookVehicle( request )( response ) {
            if ( is_defined( request.vehicleId ) ) {
                println@Console("[GATEWAY] Richiesta Prenotazione: " + request.vehicleId)();
                
                // 1. Pre-autorizzazione Bancaria (Coreografia - Ramo 2)
                scope( bankScope ) {
                    install( InsufficientFunds => 
                        response.success = false;
                        response.message = "Prenotazione fallita: Fondi insufficienti.";
                        println@Console("[GATEWAY] Prenotazione fallita: Fondi insufficienti")()
                    );
                    install( AccountSuspended =>
                        response.success = false;
                        response.message = "Prenotazione fallita: Account sospeso.";
                        println@Console("[GATEWAY] Prenotazione fallita: Account sospeso")()
                    );

                    preAuthorize@Bank( { 
                        .clientName = request.clientName,
                        .cardNumber = request.cardNumber 
                    } )( bankResponse );

                    // Salviamo il token di pagamento per il futuro pickup
                    synchronized( gatewayLock ) {
                        global.payment_tokens.(request.vehicleId) = bankResponse.paymentToken
                    }
                };

                if ( !is_defined(response.success) || response.success == true ) {
                    setStatus@Tracking( { .vehicleId = request.vehicleId, .status = "RESERVED" } )();
                    response.success = true;
                    response.message = "Veicolo prenotato con successo. Cauzione bloccata."
                }
            } else {
                response.success = false;
                response.message = "Errore: ID Veicolo mancante."
            }
        } ]

        [ registerUser( request )( response ) {
            if ( is_defined( request.username ) && is_defined( request.password ) ) {
                synchronized( gatewayLock ) {
                    if ( is_defined( global.users.(request.username) ) ) {
                        response.success = false;
                        response.message = "Errore: L'utente " + request.username + " esiste già!"
                    } else {
                        global.users.(request.username) = request.password;
                        println@Console("[GATEWAY] Nuovo utente registrato: " + request.username)();
                        response.success = true;
                        response.message = "Registrazione avvenuta con successo!"
                    }
                }
            } else {
                response.success = false;
                response.message = "Dati mancanti (username o password)."
            }
        } ]

        [ getMap( request )( response ) {
            getVehicleList@Tracking()( trackingData );
            response.vehicles -> trackingData.vehicles
        } ]

        [ handleOptions( request )( response ) {
            nullProcess 
        } ]
    }
}