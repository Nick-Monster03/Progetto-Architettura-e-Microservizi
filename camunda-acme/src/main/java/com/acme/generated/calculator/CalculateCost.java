
package com.acme.generated.calculator;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlRootElement;
import jakarta.xml.bind.annotation.XmlType;


/**
 * <p>Java class for anonymous complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
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
     * Gets the value of the needsPenaltyTime property.
     * 
     */
    public boolean isNeedsPenaltyTime() {
        return needsPenaltyTime;
    }

    /**
     * Sets the value of the needsPenaltyTime property.
     * 
     */
    public void setNeedsPenaltyTime(boolean value) {
        this.needsPenaltyTime = value;
    }

    /**
     * Gets the value of the durationMinutes property.
     * 
     */
    public double getDurationMinutes() {
        return durationMinutes;
    }

    /**
     * Sets the value of the durationMinutes property.
     * 
     */
    public void setDurationMinutes(double value) {
        this.durationMinutes = value;
    }

    /**
     * Gets the value of the finalBatteryLevel property.
     * 
     */
    public int getFinalBatteryLevel() {
        return finalBatteryLevel;
    }

    /**
     * Sets the value of the finalBatteryLevel property.
     * 
     */
    public void setFinalBatteryLevel(int value) {
        this.finalBatteryLevel = value;
    }

    /**
     * Gets the value of the kilometers property.
     * 
     */
    public double getKilometers() {
        return kilometers;
    }

    /**
     * Sets the value of the kilometers property.
     * 
     */
    public void setKilometers(double value) {
        this.kilometers = value;
    }

}
