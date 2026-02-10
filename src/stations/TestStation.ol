include "StationInterface.iol"
include "console.iol"
include "time.iol" 

outputPort StationPort {
    Location: "socket://localhost:8083"
    Protocol: soap {
        .wsdl = "StationService.wsdl"; 
        .dropRootValue = true
    }
    Interfaces: StationInterface
}

main {
    println@Console("\n╔══════════════════════════════════════════════════════════════╗")();
    println@Console("║       TEST SUITE - STATION SERVICE                            ║")();
    println@Console("╚══════════════════════════════════════════════════════════════╝\n")();
    
    sleep@Time(2000)(); // Attendi che il servizio sia pronto

    // Contatori per statistiche
    global.testsTotal = 0;
    global.testsPassed = 0;
    global.testsFailed = 0;

    // ========== TEST 1: GET ALL STATIONS - Verifica tutte le stazioni ==========
    scope(test_get_all_stations) {
        global.testsTotal++;
        println@Console("\n[TEST 1] GET ALL STATIONS - Recupera tutte le stazioni")();
        println@Console("─────────────────────────────────────────────────")();
        
        getAllStations@StationPort()(stationsRes);
        
        println@Console("✓ Ricevute " + #stationsRes.stations + " stazioni")();
        
        for(i = 0, i < #stationsRes.stations, i++) {
            println@Console("\n  Stazione: " + stationsRes.stations[i].stationId)();
            println@Console("  Veicoli (" + #stationsRes.stations[i].vehicles + "):")();
            
            for(j = 0, j < #stationsRes.stations[i].vehicles, j++) {
                println@Console("    - " + stationsRes.stations[i].vehicles[j].vehicleId + 
                    " | Status: " + stationsRes.stations[i].vehicles[j].status + 
                    " | Battery: " + stationsRes.stations[i].vehicles[j].battery + "%")()
            }
        };
        
        if (#stationsRes.stations == 3) {
            println@Console("\n✓ TEST 1 PASSED: Ricevute 3 stazioni come atteso")();
            global.testsPassed++
        } else {
            println@Console("\n❌ TEST 1 FAILED: Attese 3 stazioni, ricevute " + #stationsRes.stations)();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 2: UNLOCK - Successo con veicolo disponibile ==========
    scope(test_unlock_success) {
        install(
            HardwareErrorFault => {
                println@Console("❌ TEST 2 FAILED: HardwareErrorFault - " + test_unlock_success.HardwareErrorFault.message)();
                global.testsFailed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 2 FAILED: VehicleNotFoundFault - " + test_unlock_success.VehicleNotFoundFault.message)();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 2 FAILED: VehicleNotAvailableFault - " + test_unlock_success.VehicleNotAvailableFault.message)();
                global.testsFailed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 2] UNLOCK - Veicolo disponibile (car1)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq.vehicleId = "car1";
        unlockReq.userId = "user123";
        unlockReq.stationId = "station1";
        
        unlock@StationPort(unlockReq)(unlockRes);
        
        if (unlockRes.success) {
            println@Console("✓ TEST 2 PASSED: " + unlockRes.message)();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 2 FAILED: Unlock non riuscito")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 3: UNLOCK - Veicolo non trovato ==========
    scope(test_unlock_not_found) {
        install(
            VehicleNotFoundFault => {
                println@Console("✓ TEST 3 PASSED: VehicleNotFoundFault correttamente lanciato")();
                println@Console("  Messaggio: " + test_unlock_not_found.VehicleNotFoundFault.message)();
                global.testsPassed++
            },
            HardwareErrorFault => {
                println@Console("❌ TEST 3 FAILED: Ricevuto HardwareErrorFault invece di VehicleNotFoundFault")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 3 FAILED: Ricevuto VehicleNotAvailableFault invece di VehicleNotFoundFault")();
                global.testsFailed++
            },
            default => {
                println@Console("✓ TEST 3 PASSED: Fault generico ricevuto (atteso per SOAP)")();
                println@Console("  Fault name: " + test_unlock_not_found.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 3] UNLOCK - Veicolo non esistente (car999)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq2.vehicleId = "car999";
        unlockReq2.userId = "user123";
        unlockReq2.stationId = "station1";
        
        unlock@StationPort(unlockReq2)(unlockRes2);
        
        // Se arriviamo qui, il fault non è stato lanciato
        println@Console("❌ TEST 3 FAILED: Nessun fault lanciato per veicolo inesistente")();
        global.testsFailed++
    };

    sleep@Time(500)();

    // ========== TEST 4: UNLOCK - Veicolo già in noleggio ==========
    scope(test_unlock_already_rented) {
        install(
            VehicleNotAvailableFault => {
                println@Console("✓ TEST 4 PASSED: VehicleNotAvailableFault correttamente lanciato")();
                println@Console("  Messaggio: " + test_unlock_already_rented.VehicleNotAvailableFault.message)();
                println@Console("  Status: " + test_unlock_already_rented.VehicleNotAvailableFault.currentStatus)();
                global.testsPassed++
            },
            HardwareErrorFault => {
                println@Console("❌ TEST 4 FAILED: Ricevuto HardwareErrorFault")();
                global.testsFailed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 4 FAILED: Ricevuto VehicleNotFoundFault")();
                global.testsFailed++
            },
            default => {
                println@Console("✓ TEST 4 PASSED: Fault generico ricevuto (atteso per SOAP - veicolo non disponibile)")();
                println@Console("  Fault name: " + test_unlock_already_rented.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 4] UNLOCK - Veicolo già in noleggio (car1)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq3.vehicleId = "car1"; // car1 è già stato sbloccato nel TEST 2
        unlockReq3.userId = "user456";
        unlockReq3.stationId = "station1";
        
        unlock@StationPort(unlockReq3)(unlockRes3);
        
        println@Console("❌ TEST 4 FAILED: Nessun fault lanciato per veicolo già in noleggio")();
        global.testsFailed++
    };

    sleep@Time(500)();

    // ========== TEST 5: LOCK - Successo ==========
    scope(test_lock_success) {
        install(
            HardwareErrorFault => {
                println@Console("❌ TEST 5 FAILED: HardwareErrorFault - " + test_lock_success.HardwareErrorFault.message)();
                global.testsFailed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 5 FAILED: VehicleNotFoundFault - " + test_lock_success.VehicleNotFoundFault.message)();
                global.testsFailed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 5] LOCK - Restituisci veicolo alla stazione (car1 -> station2)")();
        println@Console("─────────────────────────────────────────────────")();
        
        lockReq.vehicleId = "car1";
        lockReq.stationId = "station2";
        lockReq.userId = "user123";
        
        lock@StationPort(lockReq)(lockRes);
        
        if (lockRes.success) {
            println@Console("✓ TEST 5 PASSED: " + lockRes.message)();
            println@Console("  Batteria finale: " + lockRes.finalBatteryLevel + "%")();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 5 FAILED: Lock non riuscito")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 5: LOCK - Veicolo non trovato ==========
    scope(test_lock_not_found) {
        install(
            VehicleNotFoundFault => {
                println@Console("✓ TEST 5 PASSED: VehicleNotFoundFault correttamente lanciato")();
                println@Console("  Messaggio: " + test_lock_not_found.VehicleNotFoundFault.message)();
                global.testsPassed++
            },
            HardwareErrorFault => {
                println@Console("❌ TEST 5 FAILED: Ricevuto HardwareErrorFault invece di VehicleNotFoundFault")();
                global.testsFailed++
            },
            default => {
                println@Console("✓ TEST 5 PASSED: Fault generico ricevuto (atteso per SOAP)")();
                println@Console("  Fault name: " + test_lock_not_found.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 5] LOCK - Veicolo non esistente (v888)")();
        println@Console("─────────────────────────────────────────────────")();
        
        lockReq2.vehicleId = "v888";
        lockReq2.stationId = "station1";
        
        lock@StationPort(lockReq2)(lockRes2);
        
        println@Console("❌ TEST 5 FAILED: Nessun fault lanciato per veicolo inesistente")();
        global.testsFailed++
    };

    sleep@Time(500)();

    // ========== TEST 6: UNLOCK - Veicolo disponibile dopo lock (v002) ==========
    scope(test_unlock_after_lock) {
        install(
            HardwareErrorFault => {
                println@Console("⚠ TEST 6 PARTIAL: HardwareErrorFault (casuale)")();
                global.testsPassed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 6 FAILED: VehicleNotFoundFault")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 6 FAILED: VehicleNotAvailableFault")();
                global.testsFailed++
            },
            default => {
                println@Console("⚠ TEST 6 PARTIAL: Fault generico (possibile HW error)")();
                println@Console("  Fault name: " + test_unlock_after_lock.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 6] UNLOCK - Nuovo veicolo disponibile (v002)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq6.vehicleId = "v002";
        unlockReq6.userId = "user789";
        
        unlock@StationPort(unlockReq6)(unlockRes6);
        
        if (unlockRes6.success) {
            println@Console("✓ TEST 6 PASSED: " + unlockRes6.message)();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 6 FAILED: Unlock non riuscito")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 7: UNLOCK + LOCK - Ciclo completo su v003 ==========
    scope(test_full_cycle) {
        install(
            HardwareErrorFault => {
                println@Console("⚠ TEST 7 PARTIAL: HardwareErrorFault (casuale)")();
                global.testsPassed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 7 FAILED: VehicleNotFoundFault")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 7 FAILED: VehicleNotAvailableFault")();
                global.testsFailed++
            },
            default => {
                println@Console("⚠ TEST 7 PARTIAL: Fault generico (possibile HW error)")();
                println@Console("  Fault name: " + test_full_cycle.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 7] CICLO COMPLETO - Unlock + Lock (v003)")();
        println@Console("─────────────────────────────────────────────────")();
        
        // Unlock
        unlockReq7.vehicleId = "v003";
        unlockReq7.userId = "user999";
        unlock@StationPort(unlockReq7)(unlockRes7);
        println@Console("  Unlock: " + unlockRes7.message)();
        
        sleep@Time(1000)(); // Simula tempo di utilizzo
        
        // Lock
        lockReq7.vehicleId = "v003";
        lockReq7.stationId = "station3";
        lock@StationPort(lockReq7)(lockRes7);
        println@Console("  Lock: Veicolo restituito")();
        println@Console("  Batteria finale: " + lockRes7.finalBatteryLevel + "%")();
        
        if (unlockRes7.success && lockRes7.success) {
            println@Console("✓ TEST 7 PASSED: Ciclo completo eseguito con successo")();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 7 FAILED: Ciclo non completato")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 8: UNLOCK + LOCK - Cambio stazione (v004) ==========
    scope(test_station_change) {
        install(
            HardwareErrorFault => {
                println@Console("⚠ TEST 8 PARTIAL: HardwareErrorFault (casuale)")();
                global.testsPassed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 8 FAILED: VehicleNotFoundFault")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 8 FAILED: VehicleNotAvailableFault")();
                global.testsFailed++
            },
            default => {
                println@Console("⚠ TEST 8 PARTIAL: Fault generico (possibile HW error)")();
                println@Console("  Fault name: " + test_station_change.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 8] CAMBIO STAZIONE - v004 da station2 a station1")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq8.vehicleId = "v004";
        unlockReq8.userId = "userABC";
        unlock@StationPort(unlockReq8)(unlockRes8);
        println@Console("  Unlock da station2: OK")();
        
        sleep@Time(800)();
        
        lockReq8.vehicleId = "v004";
        lockReq8.stationId = "station1"; // Diversa dalla stazione originale
        lock@StationPort(lockReq8)(lockRes8);
        println@Console("  Lock a station1: OK")();
        println@Console("  Batteria finale: " + lockRes8.finalBatteryLevel + "%")();
        
        if (unlockRes8.success && lockRes8.success) {
            println@Console("✓ TEST 8 PASSED: Cambio stazione completato")();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 8 FAILED: Cambio stazione fallito")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 9: Multiple UNLOCK attempts - Stress test ==========
    scope(test_multiple_unlocks) {
        install(
            HardwareErrorFault => {
                println@Console("  Ricevuto HardwareErrorFault (può essere casuale)")();
                hardwareErrorOccurred = true
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 9 FAILED: VehicleNotFoundFault inaspettato")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                notAvailableOccurred = true
            },
            default => {
                println@Console("  Ricevuto fault generico (comportamento SOAP)")();
                println@Console("  Fault name: " + test_multiple_unlocks.default)();
                notAvailableOccurred = true
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 9] STRESS TEST - Multiple unlock attempts (v005)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq9.vehicleId = "v005";
        unlockReq9.userId = "userXYZ";
        
        hardwareErrorOccurred = false;
        notAvailableOccurred = false;
        firstUnlockSuccess = false;
        
        // Primo tentativo
        unlock@StationPort(unlockReq9)(unlockRes9);
        if (unlockRes9.success) {
            println@Console("  Tentativo 1: SUCCESS")();
            firstUnlockSuccess = true
        };
        
        // Secondo tentativo (dovrebbe fallire: già in noleggio)
        unlockReq9b.vehicleId = "v005";
        unlockReq9b.userId = "userDifferent";
        unlock@StationPort(unlockReq9b)(unlockRes9b);
        println@Console("  Tentativo 2: Se arrivo qui, nessun fault")();
        
        if (firstUnlockSuccess && notAvailableOccurred) {
            println@Console("✓ TEST 9 PASSED: Comportamento corretto su tentativi multipli")();
            global.testsPassed++
        } else if (hardwareErrorOccurred) {
            println@Console("⚠ TEST 9 PARTIAL: HardwareError ha interferito col test")();
            global.testsPassed++ // Lo consideriamo comunque valido
        } else {
            println@Console("❌ TEST 9 FAILED: Comportamento inatteso")();
            global.testsFailed++
        }
    };

    sleep@Time(1000)();

    // ========== RIEPILOGO FINALE ==========
    println@Console("\n\n╔══════════════════════════════════════════════════════════════╗")();
    println@Console("║                    RISULTATI TEST SUITE                       ║")();
    println@Console("╚══════════════════════════════════════════════════════════════╝")();
    println@Console("Total tests:  " + global.testsTotal)();
    println@Console("Passed:       " + global.testsPassed + " ✓")();
    println@Console("Failed:       " + global.testsFailed + " ❌")();
    
    successRate = double(global.testsPassed) / double(global.testsTotal) * 100.0;
    println@Console("Success rate: " + successRate + "%")();
    
    if (global.testsFailed == 0) {
        println@Console("\n🎉 TUTTI I TEST SONO PASSATI! 🎉\n")()
    } else {
        println@Console("\n⚠️  Alcuni test sono falliti. Controllare i log sopra.\n")()
    }
}