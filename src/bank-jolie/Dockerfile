# FROM jolielang/jolie
# EXPOSE 8008
# COPY . /app
# WORKDIR /app
# CMD jolie BankService.ol
FROM jolielang/jolie
EXPOSE 8008
COPY . /app
WORKDIR /app
RUN wget -q -O /usr/lib/jolie/lib/jdbc-postgresql.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.3.jar
CMD jolie BankService.ol

