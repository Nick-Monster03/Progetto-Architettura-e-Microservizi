const GATEWAY_URL = "http://localhost:8082"; // Indirizzo del FleetGateway.ol

const app = {
    map: null,
    user: null,
    markers: {},
    currentRentalId: null,

    init: function () {
        // Inizializza mappa su Roma (Colosseo)
        this.map = L.map('map', { zoomControl: false }).setView([41.8902, 12.4922], 14);
        
        // Aggiungiamo i controlli dello zoom in alto a destra per non coprire la nostra card
        L.control.zoom({ position: 'topright' }).addTo(this.map);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap © CARTO'
        }).addTo(this.map);

        // Controllo se c'è già un utente salvato in sessione
        const savedUser = localStorage.getItem('acme_user');
        if (savedUser) {
            this.user = savedUser;
            this.updateUI('logged');
            this.refreshMap();
        }
    },

    // --- AUTENTICAZIONE ---

    login: function () {
        const user = document.getElementById('username').value;
        const pass = document.getElementById('password').value;

        if (!user || !pass) {
            return Swal.fire({ icon: 'error', title: 'Oops...', text: 'Inserisci username e password!' });
        }
        
        Swal.fire({ title: 'Accesso in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch(`${GATEWAY_URL}/loginUser`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                this.user = user;
                localStorage.setItem('acme_user', user); 

                // Chiusura sicura della modale
                const modalEl = document.getElementById('loginModal');
                let modal = bootstrap.Modal.getInstance(modalEl);
                if (!modal) modal = new bootstrap.Modal(modalEl);
                modal.hide();
                document.body.classList.remove('modal-open');
                document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());

                this.updateUI('logged');
                this.refreshMap();
                
                Swal.fire({ icon: 'success', title: 'Accesso Effettuato', text: res.message, timer: 1500, showConfirmButton: false });
            } else {
                Swal.fire({ icon: 'error', title: 'Accesso Negato', text: res.message });
            }
        })
        .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: 'Impossibile contattare il Gateway.' }));
    },

    register: function() {
        const user = document.getElementById('reg-username').value;
        const pass = document.getElementById('reg-password').value;

        if (!user || !pass) {
            return Swal.fire({ icon: 'warning', text: 'Inserisci username e password!' });
        }

        Swal.fire({ title: 'Registrazione in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch(`${GATEWAY_URL}/registerUser`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                // Chiusura sicura della modale
                const modalEl = document.getElementById('registerModal');
                let modal = bootstrap.Modal.getInstance(modalEl);
                if (!modal) modal = new bootstrap.Modal(modalEl);
                modal.hide();
                document.body.classList.remove('modal-open');
                document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());

                // Precompila il login
                document.getElementById('username').value = user; 
                Swal.fire({ icon: 'success', title: 'Registrato!', text: res.message });
            } else {
                Swal.fire({ icon: 'error', title: 'Errore', text: res.message });
            }
        })
        .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: 'Impossibile contattare il Gateway.' }));
    },

    logout: function() {
        this.user = null;
        localStorage.removeItem('acme_user');
        this.updateUI('guest');
    },

    // --- GESTIONE INTERFACCIA (UI) ---

    updateUI: function(state) {
        const guestSec = document.getElementById('guest-section');
        const loggedSec = document.getElementById('logged-section');
        const rentingSec = document.getElementById('renting-section');

        guestSec.classList.add('d-none');
        loggedSec.classList.add('d-none');
        rentingSec.classList.add('d-none');

        if (state === 'guest') {
            guestSec.classList.remove('d-none');
        } else if (state === 'logged') {
            document.getElementById('user-display').innerText = this.user;
            loggedSec.classList.remove('d-none');
        } else if (state === 'renting') {
            document.getElementById('current-vehicle-id').innerText = this.currentRentalId;
            rentingSec.classList.remove('d-none');
        }
    },

    // --- LOGICA VEICOLI E MAPPA ---

    refreshMap: function () {
        const vehicleIds = ["v1", "v2", "v3", "v-test"];

        vehicleIds.forEach(vid => {
            fetch(`${GATEWAY_URL}/getStatus?vehicleId=${vid}`)
                .then(res => res.ok ? res.json() : Promise.reject("Errore HTTP"))
                .then(data => this.updateMarker(data))
                .catch(err => console.log(`Veicolo ${vid} non reperibile al momento.`));
        });
    },

    updateMarker: function (vehicleData) {
        if (!vehicleData || !vehicleData.latitude || (vehicleData.latitude === 0 && vehicleData.longitude === 0)) return;

        // Se in noleggio è rosso, se libero è verde
        let isRented = vehicleData.status === "RENTED";
        let color = isRented ? "#e74c3c" : "#2ecc71";

        if (this.markers[vehicleData.vehicleId]) {
            this.markers[vehicleData.vehicleId].setLatLng([vehicleData.latitude, vehicleData.longitude]);
            this.markers[vehicleData.vehicleId].setStyle({ color: color, fillColor: color });
        } else {
            const marker = L.circleMarker([vehicleData.latitude, vehicleData.longitude], {
                color: '#ffffff', weight: 2, fillColor: color, fillOpacity: 0.9, radius: 10
            }).addTo(this.map);

            marker.bindPopup(`
                <div class="text-center p-1">
                    <h6 class="fw-bold mb-1"><i class="bi bi-scooter"></i> ${vehicleData.vehicleId}</h6>
                    <span class="badge ${isRented ? 'bg-danger' : 'bg-success'} mb-2">${vehicleData.status}</span><br>
                    <small>🔋 Batteria: <b>${vehicleData.batteryLevel}%</b></small><br>
                    <button class="btn btn-sm btn-outline-warning mt-2 fw-bold w-100" onclick="app.prenota('${vehicleData.vehicleId}')">Prenota</button>
                </div>
            `);

            this.markers[vehicleData.vehicleId] = marker;
        }
    },

    // --- NOLEGGIO ---

    scanQR: function () {
        Swal.fire({
            title: 'Inquadra il QR Code',
            text: "Per simulare, digita l'ID del veicolo (es. v1):",
            input: 'text',
            inputAttributes: { autocapitalize: 'off' },
            showCancelButton: true,
            confirmButtonText: 'Sblocca',
            cancelButtonText: 'Annulla',
            confirmButtonColor: '#198754'
        }).then((result) => {
            if (result.isConfirmed && result.value) {
                this.startRental(result.value);
            }
        });
    },

    startRental: function (vehicleId) {
        Swal.fire({ title: 'Sblocco veicolo...', didOpen: () => Swal.showLoading() });

        fetch(`${GATEWAY_URL}/startTracking`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleId: vehicleId, userId: this.user })
        })
        .then(res => res.json())
        .then(res => {
            if(res.success) {
                this.currentRentalId = vehicleId;
                this.updateUI('renting');
                this.refreshMap();
                Swal.fire({ icon: 'success', title: 'Sbloccato!', text: '🛴 Buon viaggio, rispetta il codice della strada!' });
            } else {
                Swal.fire({ icon: 'error', title: 'Impossibile sbloccare', text: res.message });
            }
        });
    },

    stopRental: function () {
        if (!this.currentRentalId) return;

        Swal.fire({ title: 'Chiusura noleggio...', didOpen: () => Swal.showLoading() });

        fetch(`${GATEWAY_URL}/stopTracking`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleId: this.currentRentalId, userId: this.user })
        })
        .then(res => res.json())
        .then(res => {
            this.currentRentalId = null;
            this.updateUI('logged');
            this.refreshMap();
            Swal.fire({ 
                icon: 'info', 
                title: 'Noleggio Terminato', 
                html: `Hai parcheggiato correttamente.<br><b>${res.message}</b>` 
            });
        });
    },

    prenota: function (vehicleId) {
        if (!this.user) return Swal.fire('Attenzione', 'Devi fare il login prima di prenotare!', 'warning');
        
        Swal.fire({
            title: `Prenotare ${vehicleId}?`,
            text: "Ti riserviamo il veicolo per 30 minuti.",
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: '#ffc107',
            confirmButtonText: 'Sì, prenota',
            cancelButtonText: 'Annulla'
        }).then((result) => {
            if (result.isConfirmed) {
                fetch(`${GATEWAY_URL}/bookVehicle`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ vehicleId: vehicleId, userId: this.user })
                })
                .then(res => res.json())
                .then(res => {
                    Swal.fire('Completato', res.message, 'success');
                    this.refreshMap();
                }).catch(err => Swal.fire('Errore', "Impossibile prenotare ora.", 'error'));
            }
        });
    }
};

// Avvio applicazione al caricamento
document.addEventListener('DOMContentLoaded', () => app.init());