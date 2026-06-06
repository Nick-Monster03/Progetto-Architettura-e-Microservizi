FROM jolielang/jolie:latest
WORKDIR /app
COPY . .
RUN wget -q -O /usr/lib/jolie/lib/jdbc-postgresql.jar https://jdbc.postgresql.org/download/postgresql-42.7.3.jar
EXPOSE 8083
CMD ["jolie", "StationService.ol"]
