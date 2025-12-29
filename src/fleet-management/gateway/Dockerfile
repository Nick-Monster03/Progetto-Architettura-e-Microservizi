FROM jolielang/jolie
EXPOSE 8082

# Copia tutto il contenuto di 'fleet-management' (gateway, tracking, battery) in /app
COPY . /app

# Ci spostiamo nella cartella del gateway per eseguire il servizio
WORKDIR /app/gateway

# Ora l'include "../tracking/..." funzionerà perché la cartella tracking esiste in /app/tracking
CMD jolie FleetGateway.ol