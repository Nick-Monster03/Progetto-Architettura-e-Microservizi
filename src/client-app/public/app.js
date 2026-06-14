const GATEWAY_URL = "http://localhost:8082";
const CAMUNDA_URL = "http://localhost:8080/engine-rest";

const app = {
    map: null,
    user: null,
    markers: {},
    currentRentalId: null,
    currentProcessId: null,   // ID istanza processo Camunda attiva
    currentStationId: "s1",   // Stazione di default per i test

    init: function () {
        this.map = L.map('map', { zoomControl: false }).setView([41.8902, 12.4922], 14);
        
        L.control.zoom({ position: 'topright' }).addTo(this.map);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap © CARTO'
        }).addTo(this.map);

        const savedUser = localStorage.getItem('acme_user');
        if (savedUser) {
            this.user = savedUser.toLowerCase();
            this.updateUI('logged');
            this.refreshMap();
        }
    },

    // --- AUTENTICAZIONE ---

    closeModal: function(modalId) {
        const modalEl = document.getElementById(modalId);
        if (modalEl) {
            let modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
        }
        document.body.classList.remove('modal-open');
        document.body.style.overflow = 'auto';
        document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
    },

    login: function () {
        const user = document.getElementById('username').value;
        const pass = document.getElementById('password').value;

        if (!user || !pass) {
            return Swal.fire({ icon: 'error', title: 'Oops...', text: 'Inserisci username e password!' });
        }
        
        this.closeModal('loginModal');
        Swal.fire({ title: 'Accesso in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch('/api/loginUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                this.user = user;
                localStorage.setItem('acme_user', user.toLowerCase());
                this.updateUI('logged');
                this.refreshMap();
                Swal.fire({ icon: 'success', title: 'Accesso Effettuato', text: res.message, timer: 1500, showConfirmButton: false });
            } else {
                Swal.fire({ icon: 'error', title: 'Accesso Negato', text: res.message });
            }
        })
    .catch(() => Swal.fire({ icon: 'error', title: 'Errore', text: 'Impossibile contattare UserService.' }));    },

    register: function() {
        const user = document.getElementById('reg-username').value;
        const pass = document.getElementById('reg-password').value;

        if (!user || !pass) {
            return Swal.fire({ icon: 'warning', text: 'Inserisci username e password!' });
        }
        
        this.closeModal('registerModal');
        Swal.fire({ title: 'Registrazione in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch('/api/registerUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                document.getElementById('username').value = user; 
                Swal.fire({ icon: 'success', title: 'Registrato!', text: res.message });
            } else {
                Swal.fire({ icon: 'error', title: 'Errore', text: res.message });
            }
        })
        .catch(() => Swal.fire({ icon: 'error', title: 'Errore', text: 'Impossibile contattare il Gateway.' }));
    },

    logout: function() {
        this.user = null;
        this.currentProcessId = null;
        localStorage.removeItem('acme_user');
        this.updateUI('guest');
    },

    // --- GESTIONE INTERFACCIA (UI) ---

    updateUI: function(state) {
        const guestSec   = document.getElementById('guest-section');
        const loggedSec  = document.getElementById('logged-section');
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
                .catch(() => console.log(`Veicolo ${vid} non reperibile al momento.`));
        });
    },

    updateMarker: function (vehicleData) {
        if (!vehicleData || !vehicleData.latitude || (vehicleData.latitude === 0 && vehicleData.longitude === 0)) return;

        const isRented = vehicleData.status === "RENTED" || vehicleData.status === "IN_USE";
        const color = isRented ? "#e74c3c" : "#2ecc71";

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

    // Avvia il processo BPMN su Camunda per il noleggio immediato
    startRental: function (vehicleId) {
        if (!this.user) return Swal.fire('Attenzione', 'Devi fare il login prima!', 'warning');

        Swal.fire({ title: 'Avvio noleggio...', text: 'Contatto la banca per la pre-autorizzazione...', didOpen: () => Swal.showLoading() });

        fetch(`${CAMUNDA_URL}/process-definition/key/rental-process/start`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                variables: {
                    userId:        { value: this.user,    type: "String"  },
                    vehicleId:     { value: vehicleId,    type: "String"  },
                    stationId:     { value: this.currentStationId, type: "String" },
                    isRiservation: { value: false,        type: "Boolean" },
                    rentalType:    { value: "immediate",  type: "String"  },
                    card_number:   { value: "CARD-" + this.user.toUpperCase(), type: "String" }
                }
            })
        })
        .then(res => {
            if (!res.ok) throw new Error("Camunda non raggiungibile (status " + res.status + ")");
            return res.json();
        })
        .then(proc => {
            // Salva l'ID istanza per poter inviare messaggi in seguito (es. stopRental)
            this.currentProcessId = proc.id;
            this.currentRentalId  = vehicleId;
            this.updateUI('renting');
            this.refreshMap();
            Swal.fire({
                icon: 'success',
                title: 'Noleggio avviato!',
                html: `🛴 Buon viaggio!<br><small class="text-muted">Process ID: ${proc.id}</small>`
            });
        })
        .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
    },

    // Termina il noleggio inviando il messaggio "vehicleReturned" al processo Camunda
    stopRental: function () {
        if (!this.currentRentalId) return;

        Swal.fire({ title: 'Chiusura noleggio...', text: 'Calcolo il costo finale...', didOpen: () => Swal.showLoading() });

        // Invia il messaggio al processo Camunda per far avanzare il flusso alla riconsegna
        fetch(`${CAMUNDA_URL}/message`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                messageName: "Message_endRental",
                processInstanceId: this.currentProcessId,
                processVariables: {
                    stationId: { value: this.currentStationId, type: "String" }
                }
            })
        })
        .then(res => {
            if (!res.ok) throw new Error("Errore nell'invio del messaggio a Camunda");
            this.currentRentalId  = null;
            this.currentProcessId = null;
            this.updateUI('logged');
            this.refreshMap();
            Swal.fire({
                icon: 'info',
                title: 'Noleggio Terminato',
                text: 'Veicolo riconsegnato. Il pagamento finale verrà elaborato a breve.'
            });
        })
        .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
    },

    // Avvia il processo BPMN su Camunda per la prenotazione breve
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
            if (!result.isConfirmed) return;

            Swal.fire({ title: 'Prenotazione in corso...', didOpen: () => Swal.showLoading() });

            fetch(`${CAMUNDA_URL}/process-definition/key/rental-process/start`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    variables: {
                        userId:        { value: this.user,    type: "String"  },
                        vehicleId:     { value: vehicleId,    type: "String"  },
                        stationId:     { value: this.currentStationId, type: "String" },
                        isRiservation: { value: true,         type: "Boolean" },
                        rentalType:    { value: "reservation", type: "String"  },
                        card_number:   { value: "CARD-" + this.user.toUpperCase(), type: "String" }
                    }
                })
            })
            .then(res => {
                if (!res.ok) throw new Error("Camunda non raggiungibile");
                return res.json();
            })
            .then(proc => {
                this.currentProcessId = proc.id;
                this.currentRentalId  = vehicleId;
                Swal.fire({
                    icon: 'success',
                    title: 'Prenotazione Confermata!',
                    html: `Veicolo <b>${vehicleId}</b> riservato per 30 minuti.<br><small class="text-muted">Process ID: ${proc.id}</small>`
                });
                this.refreshMap();
            })
            .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
        });
    },

    // Annulla la prenotazione inviando il messaggio "cancelRiservation" a Camunda
    cancelBooking: function () {
        if (!this.currentProcessId) return Swal.fire('Attenzione', 'Nessuna prenotazione attiva.', 'warning');

        Swal.fire({
            title: 'Annullare la prenotazione?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sì, annulla',
            cancelButtonText: 'No'
        }).then(result => {
            if (!result.isConfirmed) return;

            fetch(`${CAMUNDA_URL}/message`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    messageName: "Message_cancelReservation",
                    processInstanceId: this.currentProcessId
                })
            })
            .then(res => {
                if (!res.ok) throw new Error("Errore nell'invio del messaggio a Camunda");
                this.currentProcessId = null;
                this.currentRentalId  = null;
                this.refreshMap();
                Swal.fire({ icon: 'success', title: 'Prenotazione annullata' });
            })
            .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
        });
    }
};

// Avvio applicazione al caricamento
document.addEventListener('DOMContentLoaded', () => app.init());