FROM node:18-alpine

# Crea la cartella di lavoro
WORKDIR /app

# Copia i file di configurazione
COPY package*.json ./

# Installa le dipendenze (express, cors)
RUN npm install

# Copia tutto il resto del codice (server.js e cartella public)
COPY . .

# Espone la porta 3000 (quella definita in server.js)
EXPOSE 3000

# Avvia il server
CMD ["node", "server.js"]