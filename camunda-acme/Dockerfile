# Build
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Copia solo il pom.xml prima per sfruttare la cache dei layer Docker:
# se le dipendenze non cambiano, questo layer non viene ricostruito.
COPY pom.xml .

# Scarica tutte le dipendenze 
RUN mvn dependency:go-offline -q

# Copia i sorgenti e i WSDL 
COPY src ./src


# Build: skippa i test (girano in CI separata), genera le classi da WSDL e pacchettizza
RUN mvn clean package -DskipTests -q

#Runtime 
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copia solo il JAR finale dallo stage di build
COPY --from=build /workspace/target/camunda-acme-1.0.0.jar app.jar

# Porta di Camunda Spring Boot
EXPOSE 8080

# Profilo Spring "docker": carica application-docker.yml con gli host Docker corretti
ENTRYPOINT ["java", \
  "-Dspring.profiles.active=docker", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-jar", "app.jar"]