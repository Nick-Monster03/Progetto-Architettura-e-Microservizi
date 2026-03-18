include "console.iol"
include "DatabaseService.ol"

outputPort DB {
    Location: "socket://localhost:5432"
    Protocol: soap 
    Interfaces: DatabaseInterface
}
    
    main {
        println@Console("=== TEST DatabaseService ===")();
        
        // TEST 1: getUserBalance
        println@Console("\n[TEST 1] getUserBalance - mario")();
        balanceReq.userId = "mario";
        getUserBalance@DB(balanceReq)(balanceResp);  // ← @DB
        println@Console("  Balance: €" + balanceResp.balance)();
        
        // TEST 2: getVehicleInfo
        println@Console("\n[TEST 2] getVehicleInfo - car1")();
        vehicleReq.vehicleId = "car1";
        getVehicleInfo@DB(vehicleReq)(vehicleResp);  // ← @DB
        println@Console("  Vehicle: " + vehicleResp.vehicleId)();
        println@Console("  Status: " + vehicleResp.status)();
        println@Console("  Battery: " + vehicleResp.batteryLevel + "%")();
        
        // ... altri test ...
        
        println@Console("\n=== TEST COMPLETATI ===")()
    }
