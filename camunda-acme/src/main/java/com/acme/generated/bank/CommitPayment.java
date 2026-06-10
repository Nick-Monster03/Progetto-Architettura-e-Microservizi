
package com.acme.generated.bank;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
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
 *         &lt;element name="duration" type="{http://www.w3.org/2001/XMLSchema}int"/&gt;
 *         &lt;element name="finalAmount" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="penalty" type="{http://www.w3.org/2001/XMLSchema}double" minOccurs="0"/&gt;
 *         &lt;element name="authToken" type="{http://www.w3.org/2001/XMLSchema}string"/&gt;
 *         &lt;element name="kilometers" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="batteryLevel" type="{http://www.w3.org/2001/XMLSchema}int"/&gt;
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
    "duration",
    "finalAmount",
    "penalty",
    "authToken",
    "kilometers",
    "batteryLevel"
})
@XmlRootElement(name = "commitPayment")
public class CommitPayment {

    protected int duration;
    protected double finalAmount;
    protected Double penalty;
    @XmlElement(required = true)
    protected String authToken;
    protected double kilometers;
    protected int batteryLevel;

    /**
     * Gets the value of the duration property.
     * 
     */
    public int getDuration() {
        return duration;
    }

    /**
     * Sets the value of the duration property.
     * 
     */
    public void setDuration(int value) {
        this.duration = value;
    }

    /**
     * Gets the value of the finalAmount property.
     * 
     */
    public double getFinalAmount() {
        return finalAmount;
    }

    /**
     * Sets the value of the finalAmount property.
     * 
     */
    public void setFinalAmount(double value) {
        this.finalAmount = value;
    }

    /**
     * Gets the value of the penalty property.
     * 
     * @return
     *     possible object is
     *     {@link Double }
     *     
     */
    public Double getPenalty() {
        return penalty;
    }

    /**
     * Sets the value of the penalty property.
     * 
     * @param value
     *     allowed object is
     *     {@link Double }
     *     
     */
    public void setPenalty(Double value) {
        this.penalty = value;
    }

    /**
     * Gets the value of the authToken property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getAuthToken() {
        return authToken;
    }

    /**
     * Sets the value of the authToken property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setAuthToken(String value) {
        this.authToken = value;
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

    /**
     * Gets the value of the batteryLevel property.
     * 
     */
    public int getBatteryLevel() {
        return batteryLevel;
    }

    /**
     * Sets the value of the batteryLevel property.
     * 
     */
    public void setBatteryLevel(int value) {
        this.batteryLevel = value;
    }

}
