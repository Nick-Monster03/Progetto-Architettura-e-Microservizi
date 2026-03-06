FROM jolielang/jolie
WORKDIR /app
COPY simulation/SimulatorInterface.iol /app/
COPY simulation/SimulatorService.ol /app/
COPY fleet-management/battery/BatteryInterface.iol /app/fleet-management/battery/
COPY fleet-management/tracking/TrackingInterface.iol /app/fleet-management/tracking/
EXPOSE 8086
CMD ["jolie", "SimulatorService.ol"]