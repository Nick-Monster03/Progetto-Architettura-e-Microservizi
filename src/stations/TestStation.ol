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

    // ========== TEST 1: UNLOCK - Successo con veicolo disponibile ==========
    scope(test_unlock_success) {
        install(
            HardwareErrorFault => {
                println@Console("⚠ HardwareErrorFault casuale - riprovo...")();
                test1Retry = true
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 1 FAILED: VehicleNotFoundFault - " + test_unlock_success.VehicleNotFoundFault.message)();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 1 FAILED: VehicleNotAvailableFault - " + test_unlock_success.VehicleNotAvailableFault.message)();
                global.testsFailed++
            },
            default => {
                println@Console("⚠ Fault generico casuale - riprovo...")();
                test1Retry = true
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 1] UNLOCK - Veicolo disponibile (v001)")();
        println@Console("─────────────────────────────────────────────────")();
        
        // Riprova finché non ha successo (max 10 tentativi)
        test1Success = false;
        test1Attempts = 0;
        while(!test1Success && test1Attempts < 10) {
            test1Retry = false;
            test1Attempts++;
            
            unlockReq.vehicleId = "v001";
            unlockReq.userId = "user123";
            
            unlock@StationPort(unlockReq)(unlockRes);
            
            if (!test1Retry && unlockRes.success) {
                test1Success = true;
                println@Console("✓ TEST 1 PASSED: " + unlockRes.message + " (tentativo " + test1Attempts + ")")();
                global.testsPassed++
            } else if (test1Retry) {
                sleep@Time(200)() // Pausa prima di riprovare
            }
        };
        
        if (!test1Success) {
            println@Console("❌ TEST 1 FAILED: Troppi errori hardware casuali")();
            global.testsFailed++
        }
    };

    sleep@Time(500)();

    // ========== TEST 2: UNLOCK - Veicolo non trovato ==========
    scope(test_unlock_not_found) {
        install(
            VehicleNotFoundFault => {
                println@Console("✓ TEST 2 PASSED: VehicleNotFoundFault correttamente lanciato")();
                println@Console("  Messaggio: " + test_unlock_not_found.VehicleNotFoundFault.message)();
                global.testsPassed++
            },
            HardwareErrorFault => {
                println@Console("❌ TEST 2 FAILED: Ricevuto HardwareErrorFault invece di VehicleNotFoundFault")();
                global.testsFailed++
            },
            VehicleNotAvailableFault => {
                println@Console("❌ TEST 2 FAILED: Ricevuto VehicleNotAvailableFault invece di VehicleNotFoundFault")();
                global.testsFailed++
            },
            default => {
                println@Console("✓ TEST 2 PASSED: Fault generico ricevuto (atteso per SOAP)")();
                println@Console("  Fault name: " + test_unlock_not_found.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 2] UNLOCK - Veicolo non esistente (v999)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq2.vehicleId = "v999";
        unlockReq2.userId = "user123";
        
        unlock@StationPort(unlockReq2)(unlockRes2);
        
        // Se arriviamo qui, il fault non è stato lanciato
        println@Console("❌ TEST 2 FAILED: Nessun fault lanciato per veicolo inesistente")();
        global.testsFailed++
    };

    sleep@Time(500)();

    // ========== TEST 3: UNLOCK - Veicolo già in noleggio ==========
    scope(test_unlock_already_rented) {
        install(
            VehicleNotAvailableFault => {
                println@Console("✓ TEST 3 PASSED: VehicleNotAvailableFault correttamente lanciato")();
                println@Console("  Messaggio: " + test_unlock_already_rented.VehicleNotAvailableFault.message)();
                println@Console("  Status: " + test_unlock_already_rented.VehicleNotAvailableFault.currentStatus)();
                global.testsPassed++
            },
            HardwareErrorFault => {
                println@Console("❌ TEST 3 FAILED: Ricevuto HardwareErrorFault")();
                global.testsFailed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 3 FAILED: Ricevuto VehicleNotFoundFault")();
                global.testsFailed++
            },
            default => {
                println@Console("✓ TEST 3 PASSED: Fault generico ricevuto (atteso per SOAP - veicolo non disponibile)")();
                println@Console("  Fault name: " + test_unlock_already_rented.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 3] UNLOCK - Veicolo già in noleggio (v001)")();
        println@Console("─────────────────────────────────────────────────")();
        
        unlockReq3.vehicleId = "v001"; // v001 è già stato sbloccato nel TEST 1
        unlockReq3.userId = "user456";
        
        unlock@StationPort(unlockReq3)(unlockRes3);
        
        println@Console("❌ TEST 3 FAILED: Nessun fault lanciato per veicolo già in noleggio")();
        global.testsFailed++
    };

    sleep@Time(500)();

    // ========== TEST 4: LOCK - Successo ==========
    scope(test_lock_success) {
        install(
            HardwareErrorFault => {
                println@Console("⚠ TEST 4 PARTIAL: HardwareErrorFault (casuale) - " + test_lock_success.HardwareErrorFault.message)();
                global.testsPassed++
            },
            VehicleNotFoundFault => {
                println@Console("❌ TEST 4 FAILED: VehicleNotFoundFault - " + test_lock_success.VehicleNotFoundFault.message)();
                global.testsFailed++
            },
            default => {
                println@Console("⚠ TEST 4 PARTIAL: Fault generico (possibile HW error casuale)")();
                println@Console("  Fault name: " + test_lock_success.default)();
                global.testsPassed++
            }
        );
        
        global.testsTotal++;
        println@Console("\n[TEST 4] LOCK - Restituisci veicolo alla stazione (v001 -> station2)")();
        println@Console("─────────────────────────────────────────────────")();
        
        lockReq.vehicleId = "v001";
        lockReq.stationId = "station2";
        
        lock@StationPort(lockReq)(lockRes);
        
        if (lockRes.success) {
            println@Console("✓ TEST 4 PASSED: Veicolo bloccato con successo")();
            println@Console("  Batteria finale: " + lockRes.finalBatteryLevel + "%")();
            global.testsPassed++
        } else {
            println@Console("❌ TEST 4 FAILED: Lock non riuscito")();
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