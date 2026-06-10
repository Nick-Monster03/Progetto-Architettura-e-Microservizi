package com.acme;

//import org.camunda.bpm.spring.boot.starter.annotation.EnableProcessApplication;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Applicazione principale Camunda ACME Mobility
 * 
 * Questa è l'entry point dell'orchestratore Camunda che:
 * - Gestisce i processi BPMN di noleggio veicoli
 * - Coordina le chiamate ai servizi Jolie (Bank, Station, Fleet, Calculator)
 * - Mantiene lo stato dei processi in PostgreSQL
 */
@SpringBootApplication
//@EnableProcessApplication("acme-mobility-app")
public class CamundaApplication {

    public static void main(String[] args) {
        SpringApplication.run(CamundaApplication.class, args);
    }
}
