FROM jolielang/jolie:latest
EXPOSE 8085
COPY . /app
WORKDIR /app
RUN wget -q -O /usr/lib/jolie/lib/jdbc-postgresql.jar https://jdbc.postgresql.org/download/postgresql-42.7.3.jar
CMD ["jolie", "BatteryService.ol"]
