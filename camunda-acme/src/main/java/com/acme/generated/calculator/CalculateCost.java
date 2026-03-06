
package com.acme.generated.calculator;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlRootElement;
import jakarta.xml.bind.annotation.XmlType;


/**
 * <p>Classe Java per anonymous complex type.
 * 
 * <p>Il seguente frammento di schema specifica il contenuto previsto contenuto in questa classe.
 * 
 * <pre>
 * &lt;complexType&gt;
 *   &lt;complexContent&gt;
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType"&gt;
 *       &lt;sequence&gt;
 *         &lt;element name="needsPenaltyTime" type="{http://www.w3.org/2001/XMLSchema}boolean"/&gt;
 *         &lt;element name="durationMinutes" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="finalBatteryLevel" type="{http://www.w3.org/2001/XMLSchema}int"/&gt;
 *         &lt;element name="kilometers" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *       &lt;/sequence&gt;
 *     &lt;/restriction&gt;
 *   &lt;/complexContent&gt;
 * &lt;/complexType&gt;
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "", propOrder = {
    "needsPenaltyTime",
    "durationMinutes",
    "finalBatteryLevel",
    "kilometers"
})
@XmlRootElement(name = "calculateCost")
public class CalculateCost {

    protected boolean needsPenaltyTime;
    protected double durationMinutes;
    protected int finalBatteryLevel;
    protected double kilometers;

    /**
     * Recupera il valore della proprietà needsPenaltyTime.
     * 
     */
    public boolean isNeedsPenaltyTime() {
        return needsPenaltyTime;
    }

    /**
     * Imposta il valore della proprietà needsPenaltyTime.
     * 
     */
    public void setNeedsPenaltyTime(boolean value) {
        this.needsPenaltyTime = value;
    }

    /**
     * Recupera il valore della proprietà durationMinutes.
     * 
     */
    public double getDurationMinutes() {
        return durationMinutes;
    }

    /**
     * Imposta il valore della proprietà durationMinutes.
     * 
     */
    public void setDurationMinutes(double value) {
        this.durationMinutes = value;
    }

    /**
     * Recupera il valore della proprietà finalBatteryLevel.
     * 
     */
    public int getFinalBatteryLevel() {
        return finalBatteryLevel;
    }

    /**
     * Imposta il valore della proprietà finalBatteryLevel.
     * 
     */
    public void setFinalBatteryLevel(int value) {
        this.finalBatteryLevel = value;
    }

    /**
     * Recupera il valore della proprietà kilometers.
     * 
     */
    public double getKilometers() {
        return kilometers;
    }

    /**
     * Imposta il valore della proprietà kilometers.
     * 
     */
    public void setKilometers(double value) {
        this.kilometers = value;
    }

}
