const GATEWAY_URL = "http://localhost:8082"; // Indirizzo del FleetGateway.ol

const app = {
    map: null,
    user: null,
    markers: {},

    init: function () {
        // Inizializza mappa su Roma
        this.map = L.map('map').setView([41.9028, 12.4964], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(this.map);
    },

    login: function () {
        const user = document.getElementById('username').value;
        if (!user) return alert("Inserisci un nome utente");
        this.user = user;

        document.getElementById('login-panel').classList.add('hidden');
        document.getElementById('action-panel').classList.remove('hidden');
        document.getElementById('user-display').innerText = "Ciao, " + user;

        this.refreshMap();
    },

    // TASK B.2: Integrazione con FleetGateway
    refreshMap: function () {
        // ID dei veicoli che sappiamo esistere nel nostro sistema (simulato)
        const vehicleIds = ["v1", "v2", "v3", "v-test"];

        console.log("🔄 Richiedo aggiornamento veicoli al Gateway...");

        vehicleIds.forEach(vid => {
            // Chiama il FleetGateway reale su localhost:8082
            fetch(`${GATEWAY_URL}/getStatus?vehicleId=${vid}`)
                .then(response => {
                    if (!response.ok) throw new Error("Errore rete");
                    return response.json();
                })
                .then(data => {
                    // data = { vehicleId, status, latitude, longitude, batteryLevel }
                    console.log("Dati ricevuti per", vid, data);
                    this.updateMarker(data);
                })
                .catch(err => console.error(`Errore recupero veicolo ${vid}:`, err));
        });
    },

    updateMarker: function (vehicleData) {
        // Ignora veicoli con dati errati o coordinate a 0 (es. errore gateway)
        if (!vehicleData || !vehicleData.latitude || (vehicleData.latitude === 0 && vehicleData.longitude === 0)) return;

        let color = vehicleData.status === "RENTED" ? "red" : "green";
        let fillColor = vehicleData.status === "RENTED" ? "#e74c3c" : "#2ecc71";

        // Se il marker esiste, lo aggiorno, altrimenti lo creo
        if (this.markers[vehicleData.vehicleId]) {
            this.markers[vehicleData.vehicleId].setLatLng([vehicleData.latitude, vehicleData.longitude]);
            this.markers[vehicleData.vehicleId].setStyle({ color: color, fillColor: fillColor });
        } else {
            const marker = L.circleMarker([vehicleData.latitude, vehicleData.longitude], {
                color: color,
                fillColor: fillColor,
                fillOpacity: 0.8,
                radius: 12
            }).addTo(this.map);

            marker.bindPopup(`
                <div style="text-align:center">
                    <b>🛴 Veicolo: ${vehicleData.vehicleId}</b><br>
                    🔋 Bat: ${vehicleData.batteryLevel}%<br>
                    Stato: ${vehicleData.status}<br>
                    <button style="margin-top:5px; padding:5px 10px; background:#e67e22; color:white; border:none; border-radius:3px; cursor:pointer;" onclick="app.prenota('${vehicleData.vehicleId}')">Prenota 30min</button>
                </div>
            `);

            this.markers[vehicleData.vehicleId] = marker;
        }
    },

    scanQR: function () {
        const vid = prompt("Simulazione Camera: Inserisci ID Veicolo (es. v1):");
        if (vid) this.startRental(vid);
    },

    // Chiama POST /startTracking definito nel Gateway Jolie
    startRental: function (vehicleId) {
        fetch(`${GATEWAY_URL}/startTracking`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                vehicleId: vehicleId,
                userId: this.user
            })
        })
            .then(res => res.json())
            .then(res => {
                alert(res.message);
                this.refreshMap(); // Aggiorna la mappa per vedere il cambio di stato
            })
            .catch(err => alert("Errore durante il noleggio: " + err));
    },

    prenota: function (vehicleId) {
        alert("Funzionalità Prenotazione da collegare al processo BPMN (Task C)");
    }
};

// Avvio applicazione
app.init();