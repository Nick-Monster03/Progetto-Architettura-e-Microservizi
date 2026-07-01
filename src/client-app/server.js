const express = require('express');
const cors    = require('cors');
const xml2js  = require('xml2js');

const app  = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// ─────────────────────────────────────────────────────────────
//  Proxy → UserService (Jolie REST, porta 8005)
// ─────────────────────────────────────────────────────────────
app.post('/api/loginUser', async (req, res) => {
    try {
        const response = await fetch('http://user-service:8005/loginUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        res.json(await response.json());
    } catch (err) {
        res.status(500).json({ success: false, message: 'UserService non raggiungibile.' });
    }
});

app.post('/api/registerUser', async (req, res) => {
    try {
        const response = await fetch('http://user-service:8005/registerUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        res.json(await response.json());
    } catch (err) {
        res.status(500).json({ success: false, message: 'UserService non raggiungibile.' });
    }
});

// ─────────────────────────────────────────────────────────────
//  Proxy → StationService (Jolie SOAP, porta 8083)
//  Converte la risposta SOAP in JSON per il browser
// ─────────────────────────────────────────────────────────────
app.get('/api/stations', async (req, res) => {

    // Envelope SOAP per l'operazione getAllStations
    const soapEnvelope = `<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:xsd1="station.acme.com.xsd">
  <soapenv:Header/>
  <soapenv:Body>
    <xsd1:getAllStations/>
  </soapenv:Body>
</soapenv:Envelope>`;

    try {
        const soapResp = await fetch('http://station-service:8083', {
            method:  'POST',
            headers: {
                'Content-Type': 'text/xml;charset=UTF-8',
                'SOAPAction':   'getAllStations'
            },
            body: soapEnvelope
        });

        if (!soapResp.ok) {
            throw new Error(`StationService ha risposto con HTTP ${soapResp.status}`);
        }

        const xmlText = await soapResp.text();

        // Parsifica l'XML SOAP → oggetto JS
        const parsed = await xml2js.parseStringPromise(xmlText, {
            explicitArray:       false,
            tagNameProcessors:   [xml2js.processors.stripPrefix],
            ignoreAttrs:         true
        });

        const body = parsed?.Envelope?.Body;
        if (!body) throw new Error('Risposta SOAP malformata: Body assente');

        const getAllStationsResp = body.getAllStationsResponse;
        if (!getAllStationsResp) throw new Error('getAllStationsResponse assente nel Body');

        // Jolie serializza il campo come "stations" (nome del campo nel tipo .iol);
        // fallback a "request" per compatibilità con vecchie versioni del WSDL
        let rawStations = getAllStationsResp.stations || getAllStationsResp.request;
        if (!rawStations) rawStations = [];
        if (!Array.isArray(rawStations)) rawStations = [rawStations];

        const stations = rawStations.map(st => {
            let rawVehicles = st.vehicles || [];
            if (!Array.isArray(rawVehicles)) rawVehicles = [rawVehicles];

            return {
                stationId:  st.stationId  || '',
                name:       st.name       || st.stationId || 'Stazione',
                latitude:   parseFloat(st.latitude)  || 0,
                longitude:  parseFloat(st.longitude) || 0,
                vehicles: rawVehicles
                    .filter(v => v && v.vehicleId)
                    .map(v => ({
                        vehicleId: v.vehicleId,
                        status:    v.status   || 'UNKNOWN',
                        battery:   parseFloat(v.battery) || 0
                    }))
            };
        });

        res.json(stations);

    } catch (err) {
        console.error('[/api/stations] Errore:', err.message);
        res.status(500).json({ error: 'StationService non raggiungibile.', detail: err.message });
    }
});

// ─────────────────────────────────────────────────────────────
app.listen(port, () => {
    console.log(`📱 ACME Client App in ascolto su http://localhost:${port}`);
});