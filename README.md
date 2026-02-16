# ACMEMobility - Progetto Architettura e Microservizi

Sistema di car sharing distribuito basato su microservizi Jolie, orchestrazione BPMN con Camunda Spring Boot, e interfaccia web.

## Prerequisiti

- **Java 17** o superiore
- **Maven 3.8+** per build del progetto Spring Boot
- **Spring Boot 3.1.5** (gestito da Maven)
- **Docker** e **Docker Compose** installati sul sistema
- **PostgreSQL** (può essere avviato con Docker o standalone)
- Almeno 4GB di RAM disponibile
- Porte libere: 3000, 8008, 8080, 8082, 8083, 8084, 8085, 8086, 8089, 5432

## Struttura Servizi

| Servizio | Porta | Tecnologia | Descrizione |
|----------|-------|------------|-------------|
| **client-app** | 3000 | Node.js | Interfaccia web utente |
| **bank-service** | 8008 | Jolie (SOAP) | Gestione transazioni bancarie |
| **camunda-acme** | 8080 | Spring Boot 3 + Camunda BPM 7.20 | Orchestrazione processi BPMN |
| **fleet-gateway** | 8082 | Jolie (REST) | API Gateway per la flotta |
| **station-service** | 8083 | Jolie (SOAP) | Gestione stazioni e veicoli |
| **tracking-service** | 8084 | Jolie (SOAP) | Tracciamento GPS veicoli |
| **battery-service** | 8085 | Jolie (SOAP) | Monitoraggio batterie |
| **simulator-service** | 8086 | Jolie (SOAP) | Simulazione traffico e consumo |
| **calculator-service** | 8089 | Jolie (SOAP) | Calcolo costi noleggi |
| **postgres** | 5432 | PostgreSQL 15 | Database Camunda |

## 🚀 Avvio Progetto

### Opzione 1: Avvio con Spring Boot (Sviluppo)

#### 1. Avvia PostgreSQL

Puoi usare Docker per PostgreSQL:

```bash
cd docker
docker-compose up -d postgres
```

Oppure installa PostgreSQL localmente e crea il database:

```sql
CREATE DATABASE camunda;
CREATE USER camunda WITH PASSWORD 'camunda';
GRANT ALL PRIVILEGES ON DATABASE camunda TO camunda;
```

#### 2. Builda l'applicazione Camunda

```bash
cd camunda-acme
mvn clean install
```

Questo comando:
- Scarica tutte le dipendenze Maven (Spring Boot, Camunda BPM, PostgreSQL driver, Apache CXF)
- Compila il codice Java
- Esegue i test
- Genera il JAR eseguibile in `target/camunda-acme-1.0.0.jar`

#### 3. Avvia l'applicazione Spring Boot

```bash
# Dalla directory camunda-acme
mvn spring-boot:run
```

Oppure esegui direttamente il JAR:

```bash
java -jar target/camunda-acme-1.0.0.jar
```

#### 4. Avvia i servizi Jolie con Docker

```bash
cd docker
docker-compose up -d bank-service station-service fleet-gateway tracking-service battery-service calculator-service simulator-service client-app
```

#### 5. Verifica l'avvio

- **Camunda Cockpit**: http://localhost:8080
  - Username: `admin`
  - Password: `admin`
- **Camunda REST API**: http://localhost:8080/engine-rest
- **Client Web**: http://localhost:3000

### Opzione 2: Avvio Completo con Docker (Produzione)

### Opzione 2: Avvio Completo con Docker (Produzione)

Se preferisci avviare tutto con Docker (incluso Camunda come container):

### 1. Clona il repository
```bash
git clone <repository-url>
cd Progetto-Architettura-e-Microservizi
```

### 2. Builda il JAR di Camunda

Prima di avviare Docker, devi buildare l'applicazione Spring Boot:

```bash
cd camunda-acme
mvn clean install
cd ..
```

### 3. Naviga nella directory docker
```bash
cd docker
```

### 4. Avvia tutti i servizi
```bash
docker-compose up -d
```

Questo comando:
- Avvia PostgreSQL
- Avvia l'applicazione Camunda Spring Boot (dal JAR)
- Avvia tutti i microservizi Jolie
- Avvia il client web
- Crea la rete `acme-net` per la comunicazione interna

### 5. Verifica lo stato dei container
```bash
docker-compose ps
```

Tutti i servizi dovrebbero essere nello stato `Up`.

### 6. Accedi alle interfacce

- **Client Web**: http://localhost:3000
- **Camunda Cockpit**: http://localhost:8080
  - Username: `admin`
  - Password: `admin`
- **Camunda REST API**: http://localhost:8080/engine-rest
- **Fleet Gateway API**: http://localhost:8082

## 🔄 Sviluppo e Modifiche

### Modificare l'applicazione Camunda Spring Boot

1. Modifica i file Java in `camunda-acme/src/main/java/com/acme/`
2. Modifica i processi BPMN in `camunda-acme/src/main/resources/bpmn/`
3. Modifica la configurazione in `camunda-acme/src/main/resources/application.yml`

4. Rebuilda e riavvia:

```bash
cd camunda-acme

# Rebuilda il progetto
mvn clean install

# Riavvia l'applicazione
mvn spring-boot:run
```

Se usi Docker:

```bash
cd camunda-acme
mvn clean install
cd ../docker
docker-compose restart camunda
```

### Hot Reload con Spring Boot DevTools

Per abilitare il reload automatico durante lo sviluppo, aggiungi al `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

### Reset e Riavvio (Dopo Modifiche al Codice)

### Reset e Riavvio (Dopo Modifiche al Codice)

#### Per modifiche a Camunda (Java/BPMN):

```bash
# 1. Rebuilda il progetto Maven
cd camunda-acme
mvn clean install

# 2. Se usi Spring Boot standalone
mvn spring-boot:run

# 3. Se usi Docker
cd ../docker
docker-compose restart camunda
```

#### Per modifiche ai servizi Jolie:

Se hai modificato il codice sorgente dei servizi Jolie o i Dockerfile, devi **ricostruire le immagini** prima di riavviare.

### Procedura Completa di Reset

### Procedura Completa di Reset

```bash
cd docker

# 1. Ferma tutti i container
docker-compose down

# 2. Rebuilda Camunda (se modificato)
cd ../camunda-acme
mvn clean install
cd ../docker

# 3. Ricostruisci tutto da zero senza cache
docker-compose build --no-cache

# 4. Riavvia i servizi
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

### Maven e Spring Boot

#### Compilare il progetto
```bash
cd camunda-acme
mvn clean compile
```

#### Eseguire i test
```bash
mvn test
```

#### Creare il JAR eseguibile
```bash
mvn clean package
# Output: target/camunda-acme-1.0.0.jar
```

#### Avviare in modalità sviluppo
```bash
mvn spring-boot:run
```

#### Avviare con profilo specifico
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

#### Verificare le dipendenze
```bash
mvn dependency:tree
```

### Docker

### Docker

### Visualizza i log di tutti i servizi
```bash
docker-compose logs -f
```

### Visualizza i log di un servizio specifico
```bash
docker-compose logs -f camunda
docker-compose logs -f fleet-gateway
docker-compose logs -f tracking-service
```

### Visualizza i log di Camunda in tempo reale
```bash
# Con Docker
docker-compose logs -f camunda

# Con Spring Boot standalone
cd camunda-acme
mvn spring-boot:run
# I log appariranno nel terminale
```

### Ferma tutti i servizi
```bash
docker-compose stop
```

### Riavvia un singolo servizio
```bash
# Camunda
docker-compose restart camunda
# oppure
cd camunda-acme && mvn spring-boot:run

# Altri servizi
docker-compose restart fleet-gateway
```

### Ricostruisci un singolo servizio
```bash
# Camunda (rebuilda Maven prima)
cd camunda-acme && mvn clean install && cd ../docker
docker-compose up -d --build camunda

# Servizi Jolie
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
2. Camunda Spring Boot (attende PostgreSQL)
3. Servizi interni (tracking, battery, calculator, simulator)
4. Gateway e Station
5. Client App

### Tempi di Avvio
- **PostgreSQL**: ~10 secondi
- **Camunda Spring Boot**: ~20-30 secondi (attende il DB e carica i processi BPMN)
- **Servizi Jolie**: ~5 secondi ciascuno

### Configurazione Spring Boot

L'applicazione Camunda legge la configurazione da [camunda-acme/src/main/resources/application.yml](camunda-acme/src/main/resources/application.yml):

- **Database**: PostgreSQL su porta 5432
- **Admin User**: admin/admin
- **Auto-deployment**: I file BPMN in `resources/bpmn/` vengono deployati automaticamente
- **History Level**: audit (traccia completa)
- **Context Path**: `/` (root)

### Struttura Progetto Camunda

```
camunda-acme/
├── pom.xml                          # Dipendenze Maven
├── src/
│   ├── main/
│   │   ├── java/com/acme/
│   │   │   ├── CamundaApplication.java      # Entry point Spring Boot
│   │   │   ├── config/                      # Configurazioni Spring
│   │   │   ├── delegates/                   # Service Tasks BPMN
│   │   │   │   └── BankPreAuthDelegate.java # Delegato per pre-autorizzazione
│   │   │   └── soap/                        # Client SOAP per Jolie
│   │   └── resources/
│   │       ├── application.yml              # Configurazione applicazione
│   │       └── bpmn/                        # Processi BPMN
│   │           └── rental-process-minimal.bpmn
│   └── test/java/                           # Test unitari
└── target/
    └── camunda-acme-1.0.0.jar              # JAR eseguibile
```

### Troubleshooting

#### Maven build fallisce
```bash
# Pulisci la cache Maven
cd camunda-acme
mvn clean
rm -rf ~/.m2/repository/com/acme

# Rebuilda
mvn clean install -U
```

#### Camunda non si connette a PostgreSQL
- Verifica che PostgreSQL sia avviato: `docker-compose ps postgres`
- Controlla le credenziali in `application.yml`
- Se usi Docker, verifica la rete: `docker network inspect docker_acme-net`
- Controlla i log: `docker-compose logs postgres camunda`

#### Errore "Port 8080 already in use"
```bash
# Trova il processo che usa la porta
sudo lsof -i :8080
# Oppure
sudo netstat -tulpn | grep 8080

# Ferma Camunda o cambia porta in application.yml
```

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

#### Modifiche al codice non vengono applicate
```bash
# Per Camunda: rebuilda Maven
cd camunda-acme
mvn clean install

# Per servizi Jolie: rebuilda Docker
cd docker
docker-compose up -d --build <service-name>

# Reset completo
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### Errori di compilazione Java
- Verifica di avere Java 17: `java -version`
- Pulisci e rebuilda: `mvn clean install -U`
- Controlla il `pom.xml` per dipendenze mancanti

#### I processi BPMN non vengono deployati
- Verifica che i file `.bpmn` siano in `camunda-acme/src/main/resources/bpmn/`
- Controlla i log all'avvio: `docker-compose logs camunda | grep deployment`
- Verifica in Camunda Cockpit → Deployments

## 🔧 Sviluppo

### Aggiungere un nuovo Delegate (Service Task)

1. Crea una classe Java in `camunda-acme/src/main/java/com/acme/delegates/`:

```java
package com.acme.delegates;

import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

@Component("myDelegate")
public class MyDelegate implements JavaDelegate {
    
    @Override
    public void execute(DelegateExecution execution) throws Exception {
        // La tua logica qui
        String variable = (String) execution.getVariable("inputVar");
        execution.setVariable("outputVar", "result");
    }
}
```

2. Nel BPMN Modeler, assegna il delegate al Service Task:
   - Implementation: `Delegate Expression`
   - Delegate Expression: `${myDelegate}`

3. Rebuilda e riavvia:
```bash
mvn clean install
mvn spring-boot:run
```

### Modificare un processo BPMN

1. Apri il file `.bpmn` in Camunda Modeler
2. Modifica il diagramma
3. Salva in `camunda-acme/src/main/resources/bpmn/`
4. Riavvia Camunda per il re-deploy automatico

### Modificare un servizio Jolie

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

### Aggiungere dipendenze Maven

Modifica il [camunda-acme/pom.xml](camunda-acme/pom.xml) e aggiungi la dipendenza:

```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>my-library</artifactId>
    <version>1.0.0</version>
</dependency>
```

Poi:
```bash
cd camunda-acme
mvn clean install
```

### Configurare endpoint esterni

Modifica [camunda-acme/src/main/resources/application.yml](camunda-acme/src/main/resources/application.yml):

```yaml
# Aggiungi sotto la sezione spring
app:
  services:
    bank-url: http://localhost:8008
    station-url: http://localhost:8083
    fleet-url: http://localhost:8082
```

Poi usa nei delegate:
```java
@Value("${app.services.bank-url}")
private String bankUrl;
```

### Test dei servizi

#### Test Camunda REST API
```bash
# Lista processi deployati
curl http://localhost:8080/engine-rest/process-definition

# Avvia un'istanza di processo
curl -X POST http://localhost:8080/engine-rest/process-definition/key/rental-process/start \
  -H "Content-Type: application/json" \
  -d '{
    "variables": {
      "userId": {"value": "mario", "type": "String"},
      "vehicleId": {"value": "car1", "type": "String"}
    }
  }'

# Ottieni task attivi
curl http://localhost:8080/engine-rest/task
```

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

## 📦 Tecnologie e Versioni

### Camunda Spring Boot
- **Spring Boot**: 3.1.5
- **Camunda BPM**: 7.20.0
- **Java**: 17
- **Maven**: 3.8+
- **PostgreSQL Driver**: Gestito da Spring Boot

### Dipendenze Principali
- `camunda-bpm-spring-boot-starter-webapp`: Web UI (Cockpit, Tasklist)
- `camunda-bpm-spring-boot-starter-rest`: REST API
- `spring-boot-starter-web`: Server web embedded (Tomcat)
- `spring-boot-starter-web-services`: Supporto SOAP
- `cxf-spring-boot-starter-jaxws`: Client SOAP Apache CXF
- `postgresql`: Driver database

### Servizi Jolie
- **Jolie**: Ultima versione
- **Node.js**: 18+ (per client-app)

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