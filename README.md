# ACMEMobility – Progetto Architettura e Microservizi

Questo repository contiene un sistema distribuito di car sharing basato su microservizi Jolie e un orchestratore BPMN realizzato con Spring Boot e Camunda BPM.

L'avvio del progetto è **interamente containerizzato**: tutti i servizi (Jolie, l'orchestratore Camunda, il client web e il database PostgreSQL) vengono eseguiti e gestiti tramite Docker Compose. Non è più necessario avviare servizi localmente tramite Maven, a meno che non si stia sviluppando attivamente l'orchestratore.

## Prerequisiti

- Docker
- Docker Compose

*(Nota: Java 17 e Maven 3.8+ sono richiesti solo se si desidera compilare o sviluppare l'applicazione Spring Boot localmente per test).*

## Struttura del repository

- `docker/`: contiene il file `docker-compose.yml` configurato per avviare in un colpo solo l'intera infrastruttura (servizi, DB e Camunda).
- `camunda-acme/`: applicazione Spring Boot (Camunda) inclusiva del proprio `Dockerfile`.
- `src/`: sorgenti e Dockerfile dei microservizi Jolie e del client web (e file WSDL associati).

## Servizi e porte

Tutto il traffico tra container passa internamente alla rete `acme-net` di Docker.
Le porte mappate e raggiungibili dal tuo host (`localhost`) includono:

- **Web Client (Frontend):** `3000`
- **Camunda (Orchestratore e Dashboard):** `8080`
- **Database PostgreSQL:** `5433` (mappata dalla 5432 del container per evitare conflitti locali)
- **Servizi Jolie:**
  - `user-service`: `8005`
  - `bank-service`: `8008`
  - `fleet-gateway`: `8082`
  - `station-service`: `8083`
  - `simulator-service`: `8086`
  - `calculator-service`: `8089`

*(Nota: `tracking-service` e `battery-service` sono isolati e raggiungibili solo sulla rete Docker).*

## Avvio del Progetto

Tutto si avvia da Docker Compose, in modo riproducibile su qualsiasi macchina.

### 1) Clona il repository

```bash
git clone <URL_REPOSITORY>
cd Progetto-Architettura-e-Microservizi
```

### 2) Avvio globale con Docker

Posizionati nella cartella `docker` ed esegui i container:

```bash
cd docker
docker-compose up -d --build
```
*L'opzione `--build` è consigliata al primo avvio (o dopo modifiche al codice) per forzare la creazione di tutte le immagini, inclusa quella Spring Boot che ora è autogestita da Docker.*

**Verifica lo stato:**  
```bash
docker-compose ps
```
Nota che `camunda-acme` potrebbe impiegare fino a 30-40 secondi per raggiungere lo stato `healthy`, poiché Spring Boot richiede qualche momento per l'avvio e la configurazione iniziale del DB.

### 3) Verifica l'infrastruttura

- **Frontend:** Vai su [http://localhost:3000](http://localhost:3000).
- **Camunda Cockpit / Tasklist:** Vai su [http://localhost:8080/app/cockpit](http://localhost:8080/app/cockpit) (Credenziali di default: Username: `admin`, Password: `admin`).
- **PostgreSQL:** Connettiti usando `localhost:5433`, l'utente `camunda`, la password `camunda` e il db `camunda`.

## Modifiche Specifiche dell'architettura containerizzata

Sebbene tutto l'ambiente sia in container, è stata mantenuta la possibilità di usarlo in modo ibrido. 
- Quando avviata da Docker (`docker-compose.yml`), l'applicazione Spring Boot attiva il profilo locale: `SPRING_PROFILES_ACTIVE=docker`, agganciandosi al file `application-docker.yml` (che dialoga con il DB via container hostname `postgres`).

## Arresto e Pulizia dati

Per fermare tutto e rimuovere i container (mantenendo i dati salvati su DB):
```bash
cd docker
docker-compose down
```

Per **resettare da zero** l'intero volume dei dati (attento, resettai i processi anche su Camunda):
```bash
docker-compose down -v
```

## Sviluppo e Troubleshooting

- Se hai bisogno di fare debug massivo sul codice di Spring Boot, spegni solo il relativo container (`docker-compose stop camunda-acme`) e avvialo in console con `cd ../camunda-acme && mvn spring-boot:run`. Questo aggancerà il profilo standard (`application.yml`) che mappa internamente le porte esposte sull'host dagli altri container e dal Database.
- Durante lo sviluppo/build fuori da docker di Camunda, se riscontri l'errore "classi generati WSDL mancanti" lancia: `mvn clean generate-sources`.
