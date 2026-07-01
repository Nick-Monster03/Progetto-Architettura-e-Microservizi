const GATEWAY_URL = "http://localhost:8082";
const CAMUNDA_URL = "http://localhost:8080/engine-rest";

const app = {
    map:              null,
    user:             null,
    markers:          {},   // vehicle circleMarkers (veicoli IN_USE, posizione real-time)
    stationMarkers:   {},   // station divIcon markers
    vehicleStationMap:{},   // vehicleId → stationId (popolato da refreshMap)                                                               
    currentRentalId:  null,
    currentProcessId: null,
    currentStationId: "s1",

    // ─── INIT ────────────────────────────────────────────────
    init: function () {
        // Centro su Bari (dove sono le stazioni del seed)
        this.map = L.map('map', { zoomControl: false }).setView([41.1200, 16.8700], 15);

        L.control.zoom({ position: 'topright' }).addTo(this.map);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap © CARTO'
        }).addTo(this.map);

        this._addLegend();

        const savedUser = localStorage.getItem('acme_user');
        if (savedUser) {
            this.user = savedUser.toLowerCase();

            const savedRentalId  = localStorage.getItem('acme_rental_id');
            const savedProcessId = localStorage.getItem('acme_process_id');
            const savedStationId = localStorage.getItem('acme_station_id');

            if (savedRentalId && savedProcessId) {
                this.currentRentalId  = savedRentalId;
                this.currentProcessId = savedProcessId;
                this.currentStationId = savedStationId || 's1';
                this.updateUI('renting');
            } else if (localStorage.getItem('acme_booking_id') && savedProcessId) { // ← AGGIUNGI
                this.currentRentalId  = localStorage.getItem('acme_booking_id');
                this.currentProcessId = savedProcessId;
                this.currentStationId = savedStationId || 's1';
                this.updateUI('logged'); // updateUI mostrerà booking-info automaticamente
            } else {
                this.updateUI('logged');
            }

            this.refreshMap();
        }
    },

    _addLegend: function () {
        const legend = L.control({ position: 'bottomright' });
        legend.onAdd = () => {
            const div = L.DomUtil.create('div');
            div.style.cssText = 'background:white;padding:8px 12px;border-radius:10px;' +
                                'box-shadow:0 2px 8px rgba(0,0,0,0.2);font-size:12px;line-height:2';
            div.innerHTML =
                '<b>Legenda</b><br>' +
                '<span style="color:#1a73e8">🏢</span> Stazione <span style="font-size:9px;color:#666">(● verde = ha disponibili)</span><br>' +
                '🟢 Veicolo disponibile<br>' +
                '🟡 Veicolo prenotato<br>' +
                '🔴 Veicolo in uso / movimento<br>' +
                '⚫ Non disponibile';
            return div;
        };
        legend.addTo(this.map);
    },

    // ─── AUTENTICAZIONE ──────────────────────────────────────
    closeModal: function (modalId) {
        const el = document.getElementById(modalId);
        if (el) {
            const m = bootstrap.Modal.getInstance(el);
            if (m) m.hide();
        }
        document.body.classList.remove('modal-open');
        document.body.style.overflow = 'auto';
        document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
    },

    login: function () {
        const user = document.getElementById('username').value.trim();
        const pass = document.getElementById('password').value.trim();
        if (!user || !pass)
            return Swal.fire({ icon: 'error', title: 'Oops...', text: 'Inserisci username e password!' });

        this.closeModal('loginModal');
        Swal.fire({ title: 'Accesso in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch('/api/loginUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(r => r.json())
        .then(res => {
            if (res.success) {
                this.user = user.toLowerCase();
                localStorage.setItem('acme_user', this.user);
                this.updateUI('logged');
                this.refreshMap();
                Swal.fire({ icon: 'success', title: 'Accesso Effettuato', text: res.message,
                            timer: 1500, showConfirmButton: false });
            } else {
                Swal.fire({ icon: 'error', title: 'Accesso Negato', text: res.message });
            }
        })
        .catch(() => Swal.fire({ icon: 'error', title: 'Errore', text: 'Impossibile contattare UserService.' }));
    },

    register: function () {
        const user = document.getElementById('reg-username').value.trim();
        const pass = document.getElementById('reg-password').value.trim();
        if (!user || !pass)
            return Swal.fire({ icon: 'warning', text: 'Inserisci username e password!' });

        this.closeModal('registerModal');
        Swal.fire({ title: 'Registrazione in corso...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

        fetch('/api/registerUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, password: pass })
        })
        .then(r => r.json())
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

    logout: function () {
        this.user             = null;
        this.currentProcessId = null;
        this.currentRentalId  = null;
        localStorage.removeItem('acme_booking_id');
        localStorage.removeItem('acme_process_id'); 
        localStorage.removeItem('acme_station_id'); 
        localStorage.removeItem('acme_rental_id');
        localStorage.removeItem('acme_user');
        this.updateUI('guest');
    },

    // ─── UI ─────────────────────────────────────────────────
    updateUI: function (state) {
        document.getElementById('guest-section').classList.add('d-none');
        document.getElementById('logged-section').classList.add('d-none');
        document.getElementById('renting-section').classList.add('d-none');

        if (state === 'guest') {
            document.getElementById('guest-section').classList.remove('d-none');
        } else if (state === 'logged') {
            document.getElementById('user-display').innerText = this.user;
            document.getElementById('logged-section').classList.remove('d-none');
            const bookingId = localStorage.getItem('acme_booking_id');
        if (bookingId) {
            document.getElementById('booked-vehicle-id').innerText = bookingId;
            document.getElementById('booking-info').classList.remove('d-none');
        }
        } else if (state === 'renting') {
            document.getElementById('current-vehicle-id').innerText = this.currentRentalId;
            document.getElementById('renting-section').classList.remove('d-none');
        }
    },

    // ─── MAPPA ──────────────────────────────────────────────

    /**
     * refreshMap: chiama /api/stations (proxy → StationService SOAP getAllStations)
     * e per ogni veicolo IN_USE chiede la posizione real-time al Fleet Gateway.
     */
    refreshMap: function () {
        fetch('/api/stations')
            .then(r => {
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            })
            .then(stations => {
                const inUseIds = [];

                stations.forEach(station => {
                    this._updateStationMarker(station);
                    station.vehicles.forEach(v => {
                        // Aggiorna mappa vehicleId → stationId
                        this.vehicleStationMap[v.vehicleId] = station.stationId;
                        if (v.status === 'IN_USE' || v.status === 'UNLOCKED') {
                            inUseIds.push(v.vehicleId);
                        }
                    });
                });

                // Ottieni posizione real-time dei veicoli in movimento
                inUseIds.forEach(vid => {
                    fetch(`${GATEWAY_URL}/getStatus?vehicleId=${vid}`)
                        .then(r => r.ok ? r.json() : Promise.reject())
                        .then(data => this._updateVehicleMarker(data))
                        .catch(() => console.log(`[refreshMap] ${vid} non tracciabile.`));
                });

                // Rimuovi marker di veicoli che non sono più in movimento
                Object.keys(this.markers).forEach(vid => {
                    if (!inUseIds.includes(vid)) {
                        this.map.removeLayer(this.markers[vid]);
                        delete this.markers[vid];
                    }
                });
            })
            .catch(err => console.error('[refreshMap] Errore:', err));
    },

    /**
     * Disegna (o aggiorna) il marker di una stazione.
     * Usa un divIcon stilizzato con il nome della stazione e un pallino
     * verde/rosso che indica se ci sono veicoli disponibili.
     */
    _updateStationMarker: function (station) {
        const availableCount = station.vehicles.filter(v => v.status === 'AVAILABLE').length;
        const dotColor       = availableCount > 0 ? '#2ecc71' : '#e74c3c';

        // ── Contenuto del popup ───────────────────────────────────────────────
        const vehiclesHtml = station.vehicles.length === 0
            ? '<small class="text-muted">Nessun veicolo presente</small>'
            : station.vehicles.map(v => {
                const statusMap = {
                    'AVAILABLE': { badge: 'bg-success',          label: 'Disponibile' },
                    'RESERVED':  { badge: 'bg-warning text-dark', label: 'Prenotato'   },
                    'IN_USE':    { badge: 'bg-danger',            label: 'In uso'       },
                    'UNLOCKED':  { badge: 'bg-danger',            label: 'Sbloccato'    },
                    'CHARGING':  { badge: 'bg-info text-dark',    label: 'In carica'    },
                    'BROKEN':    { badge: 'bg-secondary',         label: 'Guasto'       }
                };
                const s = statusMap[v.status] || { badge: 'bg-secondary', label: v.status };

                const actionBtn = v.status === 'AVAILABLE'
                    ? `<button class="btn btn-sm btn-warning mt-1 w-100 fw-bold"
                               onclick="app.prenota('${v.vehicleId}', '${station.stationId}')">
                           <i class="bi bi-calendar-check"></i> Prenota
                       </button>`
                    : '';

                return `<div class="border rounded p-1 mb-1 text-start">
                            <span class="fw-bold">${v.vehicleId}</span>
                            <span class="badge ${s.badge} ms-1">${s.label}</span>
                            <br><small>🔋 ${Math.round(v.battery)}%</small>
                            ${actionBtn}
                        </div>`;
            }).join('');

        const popupContent = `
            <div style="min-width:200px">
                <h6 class="fw-bold mb-1">🏢 ${station.name}</h6>
                <small class="text-muted">${station.stationId}
                    &nbsp;·&nbsp; ${availableCount} disponibili su ${station.vehicles.length}
                </small>
                <hr class="my-2">
                ${vehiclesHtml}
            </div>`;

        // ── Icona ────────────────────────────────────────────────────────────
        const iconHtml = `
            <div style="position:relative;display:inline-block">
                <div style="background:#1a73e8;color:white;border-radius:8px;
                            padding:4px 10px;font-weight:bold;font-size:11px;
                            border:2px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.35);
                            white-space:nowrap;cursor:pointer">
                    🏢 ${station.name}
                </div>
                <div style="position:absolute;top:-4px;right:-4px;width:11px;height:11px;
                            border-radius:50%;background:${dotColor};
                            border:2px solid white;box-shadow:0 1px 3px rgba(0,0,0,0.3)">
                </div>
            </div>`;

        const icon = L.divIcon({ html: iconHtml, className: '', iconAnchor: [0, 34] });

        if (this.stationMarkers[station.stationId]) {
            this.stationMarkers[station.stationId].setIcon(icon);
            this.stationMarkers[station.stationId].setPopupContent(popupContent);
        } else {
            const marker = L.marker([station.latitude, station.longitude], { icon })
                .addTo(this.map);
            marker.bindPopup(popupContent, { maxWidth: 250 });
            this.stationMarkers[station.stationId] = marker;
        }
    },

    /**
     * Disegna (o aggiorna) il marker circolare di un veicolo IN_USE.
     * La posizione è real-time dal Fleet Gateway.
     */
    _updateVehicleMarker: function (vehicleData) {
        if (!vehicleData) return;
        const lat = vehicleData.latitude;
        const lng = vehicleData.longitude;
        if (!lat || (lat === 0 && lng === 0)) return;

        const vid    = vehicleData.vehicleId;
        const popup  = `<div class="text-center p-1">
                            <h6 class="fw-bold mb-1">🛴 ${vid}</h6>
                            <span class="badge bg-danger mb-2">IN USO</span><br>
                            <small>🔋 Batteria: <b>${vehicleData.batteryLevel}%</b></small>
                        </div>`;

        if (this.markers[vid]) {
            this.markers[vid].setLatLng([lat, lng]);
            this.markers[vid].setPopupContent(popup);
        } else {
            const m = L.circleMarker([lat, lng], {
                color: '#ffffff', weight: 2,
                fillColor: '#e74c3c', fillOpacity: 0.9, radius: 10
            }).addTo(this.map);
            m.bindPopup(popup);
            this.markers[vid] = m;
        }
    },

    // ─── NOLEGGIO ────────────────────────────────────────────

    /** Simula la scansione QR: l'utente digita l'ID del veicolo */
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
        }).then(result => {
            if (result.isConfirmed && result.value)
                this.startRental(result.value.trim());
        });
    },

    /** Avvia processo BPMN di Noleggio Immediato */
    startRental: function (vehicleId) {
        if (!this.user) return Swal.fire('Attenzione', 'Devi fare il login prima!', 'warning');
        if (this.currentProcessId && !localStorage.getItem('acme_rental_id')) {
            if (vehicleId !== this.currentRentalId) {
                return Swal.fire({
                    icon: 'warning',
                    title: 'Hai una prenotazione attiva',
                    html: `Puoi ritirare solo il veicolo <b>${this.currentRentalId}</b> che hai prenotato.`
                });
        }
        // Veicolo corretto → conferma ritiro sul processo esistente
        this._confirmPickup();
        return;
    }
        // Recupera la stazione del veicolo dall'ultima refreshMap
        const stationId = this.vehicleStationMap[vehicleId] || 's1';
        this.currentStationId = stationId;

        Swal.fire({ title: 'Avvio noleggio...', text: 'Contatto la banca per la pre-autorizzazione...', didOpen: () => Swal.showLoading() });

        fetch(`${CAMUNDA_URL}/process-definition/key/rental-process/start`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                variables: {
                    userId:        { value: this.user,      type: "String"  },
                    vehicleId:     { value: vehicleId,      type: "String"  },
                    stationId:     { value: stationId,      type: "String"  },
                    isRiservation: { value: false,          type: "Boolean" },
                    rentalType:    { value: "immediate",    type: "String"  },
                    card_number:   { value: "CARD-" + this.user.toUpperCase(), type: "String" }
                }
            })
        })
        .then(r => {
            if (!r.ok) throw new Error("Camunda non raggiungibile (status " + r.status + ")");
            return r.json();
        })
        .then(proc => {
            this.currentProcessId = proc.id;
            this.currentRentalId  = vehicleId;
            localStorage.setItem('acme_rental_id',  vehicleId);
            localStorage.setItem('acme_process_id', proc.id);
            localStorage.setItem('acme_station_id', this.currentStationId);
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

    /** Termina il noleggio: invia Message_endRental a Camunda */
    stopRental: function () {
        if (!this.currentRentalId) return;

        Swal.fire({ title: 'Chiusura noleggio...', text: 'Calcolo il costo finale...', didOpen: () => Swal.showLoading() });

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
        .then(r => {
            if (!r.ok) throw new Error("Errore nell'invio del messaggio a Camunda");
            this.currentRentalId  = null;
            this.currentProcessId = null;
            localStorage.removeItem('acme_rental_id');
            localStorage.removeItem('acme_process_id');
            localStorage.removeItem('acme_station_id');
            this.updateUI('logged');
            this.refreshMap();
            Swal.fire({ icon: 'info', title: 'Noleggio Terminato',
                        text: 'Veicolo riconsegnato. Il pagamento finale verrà elaborato a breve.' });
        })
        .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
    },

    /**
     * Avvia processo BPMN di Prenotazione Breve.
     * stationId viene passato dal pulsante nel popup della stazione.
     */
    prenota: function (vehicleId, stationId) {
        if (!this.user) return Swal.fire('Attenzione', 'Devi fare il login prima di prenotare!', 'warning');

        if (this.currentRentalId) {
        return Swal.fire({
            icon: 'warning',
            title: 'Noleggio in corso',
            text: 'Hai già un noleggio attivo. Terminalo prima di prenotare un altro veicolo.'
            });
        }
        // Imposta la stazione corretta ricevuta dal marker
        this.currentStationId = stationId || this.vehicleStationMap[vehicleId] || 's1';

        Swal.fire({
            title: `Prenotare ${vehicleId}?`,
            html:  `Stazione: <b>${this.currentStationId}</b><br>Il veicolo verrà riservato per 30 minuti.`,
            icon:  'question',
            showCancelButton:  true,
            confirmButtonColor:'#ffc107',
            confirmButtonText: 'Sì, prenota',
            cancelButtonText:  'Annulla'
        }).then(result => {
            if (!result.isConfirmed) return;

            Swal.fire({ title: 'Prenotazione in corso...', didOpen: () => Swal.showLoading() });

            fetch(`${CAMUNDA_URL}/process-definition/key/rental-process/start`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    variables: {
                        userId:        { value: this.user,              type: "String"  },
                        vehicleId:     { value: vehicleId,              type: "String"  },
                        stationId:     { value: this.currentStationId,  type: "String"  },
                        isRiservation: { value: true,                   type: "Boolean" },
                        rentalType:    { value: "reserve",          type: "String"  },
                        card_number:   { value: "CARD-" + this.user.toUpperCase(), type: "String" }
                    }
                })
            })
            .then(r => {
                if (!r.ok) throw new Error("Camunda non raggiungibile");
                return r.json();
            })
            .then(proc => {
                this.currentProcessId = proc.id;
                this.currentRentalId  = vehicleId;

                localStorage.setItem('acme_booking_id', vehicleId);
                localStorage.setItem('acme_process_id', proc.id);
                localStorage.setItem('acme_station_id', this.currentStationId);
                this.refreshMap();

                document.getElementById('booked-vehicle-id').innerText = vehicleId;
                document.getElementById('booking-info').classList.remove('d-none');
                Swal.fire({
                    icon:  'success',
                    title: 'Prenotazione Confermata!',
                    html:  `Veicolo <b>${vehicleId}</b> riservato per 30 minuti.<br>
                            <small class="text-muted">
                                Presentati alla stazione <b>${this.currentStationId}</b> per il ritiro.
                            </small>`
                });
            })
            .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
        });
    },

    /** Annulla la prenotazione attiva */

    _confirmPickup: function () {
    Swal.fire({ title: 'Ritiro veicolo...', text: 'Sblocco il veicolo prenotato...', didOpen: () => Swal.showLoading() });

    fetch(`${CAMUNDA_URL}/message`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            messageName:       "Message_confirmPickup",
            processInstanceId: this.currentProcessId
        })
    })
    .then(r => {
        if (!r.ok) throw new Error("Errore nell'invio del messaggio a Camunda");
        // Promuovi la prenotazione a noleggio effettivo
        localStorage.removeItem('acme_booking_id');
        localStorage.setItem('acme_rental_id',  this.currentRentalId);
        localStorage.setItem('acme_process_id', this.currentProcessId);
        localStorage.setItem('acme_station_id', this.currentStationId);
        this.updateUI('renting');
        this.refreshMap();
        Swal.fire({
            icon: 'success', title: 'Veicolo sbloccato!',
            html: `Buon viaggio con <b>${this.currentRentalId}</b>!`,
            timer: 2000, showConfirmButton: false
        });
    })
    .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
},

    cancelBooking: function () {
        if (!this.currentProcessId)
            return Swal.fire('Attenzione', 'Nessuna prenotazione attiva.', 'warning');

        Swal.fire({
            title: 'Annullare la prenotazione?',
            icon:  'warning',
            showCancelButton: true,
            confirmButtonText:'Sì, annulla',
            cancelButtonText: 'No'
        }).then(result => {
            if (!result.isConfirmed) return;

            fetch(`${CAMUNDA_URL}/message`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    messageName:       "Message_cancelReservation",
                    processInstanceId: this.currentProcessId
                })
            })
            .then(r => {
                if (!r.ok) throw new Error("Errore nell'invio del messaggio a Camunda");
                this.currentProcessId = null;
                this.currentRentalId  = null;
                localStorage.removeItem('acme_booking_id');
                localStorage.removeItem('acme_process_id');
                localStorage.removeItem('acme_station_id');
                document.getElementById('booking-info').classList.add('d-none');
                this.refreshMap();
                Swal.fire({ icon: 'success', title: 'Prenotazione annullata' });
            })
            .catch(err => Swal.fire({ icon: 'error', title: 'Errore', text: err.message }));
        });
    }
};

document.addEventListener('DOMContentLoaded', () => app.init());