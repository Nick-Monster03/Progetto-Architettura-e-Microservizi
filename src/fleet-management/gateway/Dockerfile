FROM jolielang/jolie:latest
WORKDIR /app

COPY fleet-management/gateway/FleetInterface.iol /app/fleet-management/gateway/
COPY fleet-management/gateway/FleetGateway.ol /app/fleet-management/gateway/

COPY fleet-management/tracking/TrackingInterface.iol /app/fleet-management/tracking/
COPY fleet-management/battery/BatteryInterface.iol /app/fleet-management/battery/
COPY simulation/SimulatorInterface.iol /app/simulation/

WORKDIR /app/fleet-management/gateway
EXPOSE 8082
CMD ["jolie", "FleetGateway.ol"]
