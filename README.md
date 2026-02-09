# ACMEMobility - Progetto Architettura e Microservizi

Sistema di car sharing distribuito basato su microservizi Jolie, orchestrazione BPMN con Camunda, e interfaccia web.

## Prerequisiti

- **Docker** e **Docker Compose** installati sul sistema
- Almeno 4GB di RAM disponibile per i container
- Porte libere: 3000, 8008, 8080, 8082, 8083, 8084, 8085, 8086, 8089, 5432

## Struttura Servizi

| Servizio | Porta | Tecnologia | Descrizione |
|----------|-------|------------|-------------|
| **client-app** | 3000 | Node.js | Interfaccia web utente |
| **bank-service** | 8008 | Jolie (SOAP) | Gestione transazioni bancarie |
| **camunda** | 8080 | Camunda BPM | Orchestrazione processi BPMN |
| **fleet-gateway** | 8082 | Jolie (REST) | API Gateway per la flotta |
| **station-service** | 8083 | Jolie (SOAP) | Gestione stazioni e veicoli |
| **tracking-service** | 8084 | Jolie (SOAP) | Tracciamento GPS veicoli |
| **battery-service** | 8085 | Jolie (SOAP) | Monitoraggio batterie |
| **simulator-service** | 8086 | Jolie (SOAP) | Simulazione traffico e consumo |
| **calculator-service** | 8089 | Jolie (SOAP) | Calcolo costi noleggi |
| **postgres** | 5432 | PostgreSQL | Database Camunda |

## 🚀 Avvio Progetto (Prima Installazione)

### 1. Clona il repository
```bash
git clone <repository-url>
cd Progetto-Architettura-e-Microservizi
```

### 2. Naviga nella directory docker
```bash
cd docker
```

### 3. Avvia tutti i servizi
```bash
docker-compose up -d
```

Questo comando:
- Scarica le immagini base necessarie (Jolie, Camunda, PostgreSQL)
- Builda le immagini personalizzate per i servizi
- Avvia tutti i container in background
- Crea la rete `acme-net` per la comunicazione interna

### 4. Verifica lo stato dei container
```bash
docker-compose ps
```

Tutti i servizi dovrebbero essere nello stato `Up`.

### 5. Accedi alle interfacce

- **Client Web**: http://localhost:3000
- **Camunda Cockpit**: http://localhost:8080/camunda
  - Username: `demo`
  - Password: `demo`
- **Fleet Gateway API**: http://localhost:8082

## 🔄 Reset e Riavvio (Dopo Modifiche al Codice)

Se hai modificato il codice sorgente dei servizi o i Dockerfile, devi **ricostruire le immagini** prima di riavviare.

### Procedura Completa di Reset

```bash
cd docker

# 1. Ferma tutti i container
docker-compose down

# 2. Rimuovi i container orfani (se presenti)
docker-compose down --remove-orphans

# 3. Rimuovi le immagini vecchie (opzionale ma consigliato)
docker-compose down --rmi local

# 4. Ricostruisci tutto da zero senza cache
docker-compose build --no-cache

# 5. Riavvia i servizi
docker-compose up -d
```

### Reset Rapido (Solo Container)

Se hai modificato **solo** file `.ol` o `.iol`:

```bash
cd docker
docker-compose down
docker-compose up -d --build
```

### Reset Completo con Database

Se vuoi anche eliminare i dati di Camunda:

```bash
cd docker
docker-compose down -v
docker-compose up -d --build
```

Il flag `-v` rimuove anche i volumi persistenti (database PostgreSQL).

## 🛠️ Comandi Utili

### Visualizza i log di tutti i servizi
```bash
docker-compose logs -f
```

### Visualizza i log di un servizio specifico
```bash
docker-compose logs -f fleet-gateway
docker-compose logs -f tracking-service
```

### Ferma tutti i servizi
```bash
docker-compose stop
```

### Riavvia un singolo servizio
```bash
docker-compose restart fleet-gateway
```

### Ricostruisci un singolo servizio
```bash
docker-compose up -d --build fleet-gateway
```

### Entra in un container
```bash
docker exec -it fleet-gateway sh
```

### Pulisci risorse Docker inutilizzate
```bash
docker system prune -a
```

## 📝 Note Importanti

### Ordine di Avvio
Docker Compose gestisce automaticamente le dipendenze, ma l'ordine logico è:
1. PostgreSQL (con healthcheck)
2. Servizi interni (tracking, battery, calculator, simulator)
3. Gateway e Station
4. Camunda 
5. Client App

### Tempi di Avvio
- **PostgreSQL**: ~10 secondi
- **Camunda**: ~30-40 secondi (attende il DB)
- **Servizi Jolie**: ~5 secondi ciascuno

### Troubleshooting

#### I servizi non comunicano tra loro
- Verifica che siano tutti sulla stessa rete: `docker network inspect docker_acme-net`
- Controlla i log per errori di connessione: `docker-compose logs`

#### Porta già in uso
```bash
# Trova il processo che usa la porta (es. 8080)
sudo lsof -i :8080
# Oppure
sudo netstat -tulpn | grep 8080
```

#### Camunda non parte
- Verifica che PostgreSQL sia healthy: `docker-compose ps postgres`
- Controlla i log: `docker-compose logs postgres camunda`

#### Modifiche al codice non vengono applicate
- Assicurati di ricostruire: `docker-compose up -d --build`
- Se persiste: reset completo con `--no-cache`

## 🔧 Sviluppo

### Modificare un servizio Jolie

1. Modifica il file `.ol` o `.iol` in `src/`
2. Se hai modificato interfacce, rigenera il WSDL (se necessario):
   ```bash
   cd src/bank-jolie
   jolie2wsdl --namespace "http://bank.acme.mobility" --portName BankPort --portAddr "http://localhost:8008" --outputFile BankService.wsdl BankService.ol
   ```
3. Ricostruisci e riavvia:
   ```bash
   cd docker
   docker-compose up -d --build <service-name>
   ```

### Test dei servizi

#### Test Bank Service (SOAP)
```bash
curl -X POST http://localhost:8008 \
  -H "Content-Type: text/xml" \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soapenv:Body>
          <preAuthorize>
            <userId>mario</userId>
            <amount>10.0</amount>
            <cardNumber>1234</cardNumber>
          </preAuthorize>
        </soapenv:Body>
      </soapenv:Envelope>'
```

#### Test Fleet Gateway (REST)
```bash
# Get status
curl http://localhost:8082/getStatus?vehicleId=car1

# Start tracking
curl -X POST http://localhost:8082/startTracking \
  -H "Content-Type: application/json" \
  -d '{"vehicleId":"car1","userId":"mario"}'
```

## 📦 Generazione WSDL

Se aggiungi nuove operazioni ai servizi SOAP, rigenera i WSDL:

```bash
# Bank Service
cd src/bank-jolie
jolie2wsdl --namespace "http://bank.acme.mobility" --portName BankPort --portAddr "http://localhost:8008" --outputFile BankService.wsdl BankService.ol

# Station Service
cd src/stations
jolie2wsdl --namespace "http://station.acme.mobility" --portName StationPort --portAddr "http://localhost:8083" --outputFile StationService.wsdl StationService.ol

# Tracking Service
cd src/fleet-management/tracking
jolie2wsdl --namespace "http://tracking.fleet.acme.mobility" --portName TrackingSocket --portAddr "http://localhost:8084" --outputFile TrackingService.wsdl TrackingService.ol

# Battery Service
cd src/fleet-management/battery
jolie2wsdl --namespace "http://battery.fleet.acme.mobility" --portName BatterySocket --portAddr "http://localhost:8085" --outputFile BatteryService.wsdl BatteryService.ol
```

## 📄 Licenza

Progetto didattico per il corso di Architettura e Microservizi.