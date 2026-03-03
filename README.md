# ACMEMobility – Progetto Architettura e Microservizi (devNick)

Questo repository contiene un sistema distribuito di car sharing basato su microservizi Jolie e un orchestratore BPMN realizzato con Spring Boot e Camunda BPM.

L’avvio del progetto prevede:
1. Avvio dei container (microservizi Jolie, client web e PostgreSQL) tramite Docker Compose.
2. Build e avvio dell’applicazione Spring Boot `camunda-acme` tramite Maven.

## Prerequisiti

- Java 17
- Maven 3.8+
- Docker e Docker Compose

## Struttura del repository

- `docker/`: contiene `docker-compose.yml` per l’avvio dei servizi containerizzati
- `camunda-acme/`: applicazione Spring Boot (Camunda) avviata tramite Maven
- `src/`: sorgenti e contesti di build Docker per microservizi Jolie e client web; contiene anche i WSDL usati per generare classi Java

## Servizi e porte

Di seguito le porte dichiarate nel file `docker/docker-compose.yml`.

### Porte pubblicate sull’host (raggiungungibili da browser/curl)

- `client-app`: 3000
- `bank-service`: 8008
- `fleet-gateway`: 8082
- `station-service`: 8083
- `simulator-service`: 8086
- `calculator-service`: 8089
- `postgres`: 5432

### Porte interne alla rete Docker (non pubblicate sull’host)

Questi servizi espongono la porta solo sulla rete Docker (`expose`), quindi non sono raggiungibili direttamente dall’host:

- `tracking-service`: 8084
- `battery-service`: 8085

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

### 3) Configura la connessione al database per l’applicazione Spring Boot

La configurazione Spring Boot si trova in:

- `camunda-acme/src/main/resources/application.yml`

Prima di avviare l’applicazione, verifica in `application.yml` che i parametri del datasource siano coerenti con il PostgreSQL avviato tramite Docker Compose (porta `5432` pubblicata sull’host).

### 4) Build dell’applicazione Spring Boot (Camunda)

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

Nota: nel `pom.xml` la generazione è configurata con `sourceRoot` impostato su `src/main/java`. Le classi generate non dovrebbero essere modificate manualmente: per aggiornamenti è necessario modificare i WSDL e rilanciare la build.

Se le classi non dovessero generarsi correttamente, esegui manualmente la fase di generazione:

```bash
mvn generate-sources
```

Oppure, per rigenerare “da pulito”:

```bash
mvn clean generate-sources
```

### 5) Avvio dell’applicazione Spring Boot

Sempre da `camunda-acme/`:

```bash
mvn spring-boot:run
```

## Nota su Camunda containerizzata

Nel file `docker-compose.yml` è presente un servizio Camunda commentato: non viene utilizzato.
In questo branch l’orchestratore viene eseguito tramite l’applicazione Spring Boot avviata con Maven (`mvn spring-boot:run`).

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

## Troubleshooting essenziale

- Se Maven fallisce per problemi legati a client SOAP o classi mancanti, esegui:
  ```bash
  cd camunda-acme
  mvn clean install
  ```
  In caso di problemi specifici sulla generazione delle classi dai WSDL:
  ```bash
  mvn clean generate-sources
  ```

- Se l’applicazione non si connette al database:
  1. verifica che `postgres` sia attivo con `docker-compose ps`
  2. controlla i parametri di datasource in `camunda-acme/src/main/resources/application.yml`
  3. verifica che la porta 5432 non sia già occupata sull’host
