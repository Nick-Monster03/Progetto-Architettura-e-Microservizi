# ACMEMobility – Progetto Architettura e Microservizi (devNick)

Questo repository contiene un sistema distribuito di car sharing basato su microservizi Jolie e un orchestratore BPMN realizzato con Spring Boot e Camunda BPM.

L'avvio del progetto prevede:
1. Avvio dei container (microservizi Jolie, client web e PostgreSQL) tramite Docker Compose.
2. Build e avvio dell'applicazione Spring Boot `camunda-acme` tramite Maven.

## Prerequisiti

- Java 17
- Maven 3.8+
- Docker e Docker Compose
- PostgreSQL 15 (eseguito tramite Docker)

## Struttura del repository

- `docker/`: contiene `docker-compose.yml` per l'avvio dei servizi containerizzati
- `camunda-acme/`: applicazione Spring Boot (Camunda) avviata tramite Maven
- `src/`: sorgenti e contesti di build Docker per microservizi Jolie e client web; contiene anche i WSDL usati per generare classi Java

## Servizi e porte

Di seguito le porte dichiarate nel file `docker/docker-compose.yml`.

### Porte pubblicate sull'host (raggiungibili da browser/curl)

- `client-app`: 3000
- `bank-service`: 8008
- `fleet-gateway`: 8082
- `station-service`: 8083
- `simulator-service`: 8086
- `calculator-service`: 8089
- `postgres`: **5433** (mappata da 5432 del container)

### Porte interne alla rete Docker (non pubblicate sull'host)

Questi servizi espongono la porta solo sulla rete Docker (`expose`), quindi non sono raggiungibili direttamente dall'host:

- `tracking-service`: 8084
- `battery-service`: 8085

## Configurazione Database PostgreSQL

### Informazioni di connessione

Il database PostgreSQL viene eseguito automaticamente tramite Docker Compose con i seguenti parametri:

| Parametro | Valore |
|-----------|--------|
| **Host** | `localhost` (da host) / `postgres` (da container) |
| **Porta** | `5433` (host) / `5432` (container) |
| **Database** | `camunda` |
| **Username** | `camunda` |
| **Password** | `camunda` |
| **Image** | `postgres:15` |

### Volumi e persistenza

Il database utilizza un volume Docker per la persistenza:
- **Volume**: `postgres-data:/var/lib/postgresql/data`
- **Scopo**: i dati rimangono disponibili anche dopo l'arresto dei container

### Health Check

PostgreSQL include un health check che verifica la disponibilità:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U camunda"]
  interval: 10s
  timeout: 5s
  retries: 5
```

Gli altri servizi dipendono da questo health check tramite `depends_on` per assicurare che il database sia pronto prima del loro avvio.

## Configurazione Spring Boot (Camunda)

### File di configurazione

La configurazione Spring Boot si trova in:
```
camunda-acme/src/main/resources/application.yml
```

### Datasource

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5433/camunda
    username: camunda
    password: camunda
    driver-class-name: org.postgresql.Driver
```

**Nota importante**: la porta è `5433` (quella mappata sull'host), non `5432`.

### Configurazione Camunda

```yaml
camunda:
  bpm:
    database:
      type: postgres
      schema-update: true
    history-level: full
```

La configurazione `schema-update: true` consente a Camunda di creare automaticamente le tabelle necessarie al primo avvio.

### Server

- **Porta**: `8080`
- **URL base**: `http://localhost:8080`
- **Context path**: `/`
- **Timeout sessione**: 30 minuti

## Avvio per la prima volta

### 1) Clona il repository e checkout del branch

```bash
git clone <URL_REPOSITORY>
cd Progetto-Architettura-e-Microservizi
git checkout devNick
```

### 2) Avvia i container

Da `docker/`:

```bash
cd docker
docker-compose up -d
```

Verifica lo stato:

```bash
docker-compose ps
```

Output atteso:
```
NAME                  COMMAND                  SERVICE              STATUS
bank-service          "docker-entrypoint.s…"   bank-service         Up (healthy)
battery-service       "docker-entrypoint.s…"   battery-service      Up (healthy)
calculator-service    "docker-entrypoint.s…"   calculator-service   Up (healthy)
client-app            "docker-entrypoint.s…"   client-app           Up
fleet-gateway         "docker-entrypoint.s…"   fleet-gateway        Up
postgres              "docker-entrypoint.s…"   postgres             Up (healthy)
simulator-service     "docker-entrypoint.s…"   simulator-service    Up
station-service       "docker-entrypoint.s…"   station-service      Up (healthy)
tracking-service      "docker-entrypoint.s…"   tracking-service     Up (healthy)
```

### 3) Verifica la connettività del database

#### Da host (tramite client PostgreSQL)

Se hai `psql` installato:

```bash
psql -h localhost -p 5433 -U camunda -d camunda
```

Password: `camunda`

#### Da container (tramite docker)

```bash
docker exec -it postgres psql -U camunda -d camunda
```

#### Comandi SQL utili

```sql
-- Verifica le tabelle create da Camunda
\dt

-- Verifica gli utenti di Camunda
SELECT * FROM camunda_user;

-- Verifica le versioni
SELECT * FROM information_schema.tables WHERE table_schema='public';
```

### 4) Build dell'applicazione Spring Boot (Camunda)

Da `camunda-acme/`:

```bash
cd camunda-acme
mvn clean install
```

#### Classi generate da WSDL

Il progetto genera automaticamente classi Java a partire da WSDL durante la fase Maven `generate-sources` tramite:

- `org.apache.cxf:cxf-codegen-plugin` (goal `wsdl2java`)

WSDL configurati nel `pom.xml`:
- `../src/bank-jolie/BankService.wsdl` → package `com.acme.generated.bank`
- `../src/stations/StationService.wsdl` → package `com.acme.generated.station`
- `../src/service-utils/CostCalculatorService.wsdl` → package `com.acme.generated.calculator`

Nota: nel `pom.xml` la generazione è configurata con `sourceRoot` impostato su `src/main/java`. Le classi generate non dovrebbero essere modificate manualmente: per aggiornamenti è necessario modificare i file WSDL e rigenerare.

Se le classi non dovessero generarsi correttamente, esegui manualmente la fase di generazione:

```bash
mvn generate-sources
```

Oppure, per rigenerare "da pulito":

```bash
mvn clean generate-sources
```

### 5) Avvio dell'applicazione Spring Boot

Sempre da `camunda-acme/`:

```bash
mvn spring-boot:run
```

L'applicazione si avvia su `http://localhost:8080`.

#### Accesso a Camunda Cockpit

Una volta avviata l'applicazione Spring Boot, puoi accedere a:

- **Cockpit** (monitoraggio processi): `http://localhost:8080/app/cockpit`
- **Tasklist** (elenco task): `http://localhost:8080/app/tasklist`
- **Admin** (amministrazione): `http://localhost:8080/app/admin`

Credenziali di default:
- **Username**: `admin`
- **Password**: `admin`

## Nota su Camunda containerizzata

Nel file `docker-compose.yml` è presente un servizio Camunda commentato: non viene utilizzato.
In questo branch l'orchestratore viene eseguito tramite l'applicazione Spring Boot avviata con Maven (`mvn spring-boot:run`).

## Arresto e pulizia

### Fermare i container

```bash
cd docker
docker-compose down
```

### Fermare i container e rimuovere i volumi (cancella i dati di Postgres)

```bash
cd docker
docker-compose down -v
```

**Avvertenza**: il comando `down -v` elimina permanentemente tutti i dati del database!

## Troubleshooting essenziale

### Problemi con il database

**Errore: "connessione rifiutata" sulla porta 5433**

1. Verifica che il container `postgres` sia attivo:
   ```bash
   cd docker
   docker-compose ps
   ```

2. Verifica che il container sia sano (status "healthy"):
   ```bash
   docker-compose logs postgres
   ```

3. Se il container è bloccato, riavvialo:
   ```bash
   docker-compose restart postgres
   ```

**Errore: "FATAL: password authentication failed"**

- Verifica che le credenziali in `application.yml` corrispondano a quelle in `docker-compose.yml`
- Credentials corrette:
  - User: `camunda`
  - Password: `camunda`
  - Database: `camunda`

**Errore: "la porta 5433 è già in uso"**

```bash
# Trova il processo che occupa la porta
lsof -i :5433  # macOS/Linux
netstat -ano | findstr :5433  # Windows

# Oppure, cambia la porta nel docker-compose.yml:
# Da: "5433:5432"
# A:  "5434:5432"
# E aggiorna di conseguenza application.yml
```

### Problemi con Maven/Camunda

**Errore: classi mancanti o client SOAP fallisce**

```bash
cd camunda-acme
mvn clean install
```

Se persiste, rigenerare le classi dai WSDL:

```bash
mvn clean generate-sources
```

**Errore: "Cannot connect to database" all'avvio di Spring Boot**

1. Verifica che PostgreSQL sia attivo e "healthy"
2. Verifica i parametri di datasource in `camunda-acme/src/main/resources/application.yml`
3. Verifica che la porta sia `5433` (non `5432`)
4. Attendi alcuni secondi dopo `docker-compose up` prima di avviare l'applicazione Spring Boot

**Errore: "column does not exist" all'avvio di Camunda**

Questo può accadere se è presente un database precedente con schema incompatibile. Soluzione:

```bash
# Ferma tutto
cd docker
docker-compose down -v

# Riavvia pulito
docker-compose up -d
```

### Problemi con Docker

**Errore: "Cannot connect to Docker daemon"**

- Assicurati che Docker Desktop sia in esecuzione
- Su Linux, verifica i permessi: `sudo usermod -aG docker $USER`

**Errore: "Dockerfile not found"**

- Verifica di trovarti nella directory `docker/` quando esegui `docker-compose`
- Verifica i percorsi relativi nei Dockerfile

## Variabili d'ambiente

I servizi utilizzano le seguenti variabili d'ambiente (definite in `docker-compose.yml`):

```yaml
# Fleet Gateway
TRACKING_HOST=tracking-service
BATTERY_HOST=battery-service
CALCULATOR_HOST=calculator-service
```

Se modifichi questi valori, ricorda di aggiornare anche gli URL in `application.yml` per Spring Boot.

## Script di inizializzazione database

Il file `docker/init-scripts/` può contenere script SQL per l'inizializzazione. Questi vengono eseguiti automaticamente all'avvio del container PostgreSQL.

Se hai script da eseguire:

```bash
# Posiziona i file in docker/init-scripts/
ls docker/init-scripts/
# Esempio: docker/init-scripts/01-init.sql
```

I file verranno eseguiti in ordine alfabetico al primo avvio.

## Riferimenti

- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Camunda Spring Boot Starter](https://docs.camunda.org/manual/latest/user-guide/spring-boot-integration/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jolie Documentation](https://jolie-lang.org/)
