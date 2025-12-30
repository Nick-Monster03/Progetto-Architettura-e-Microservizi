FROM jolielang/jolie
# Il simulatore non espone porte in ingresso, fa solo chiamate in uscita
COPY . /app
WORKDIR /app
CMD ["jolie", "SimulatorService.ol"]