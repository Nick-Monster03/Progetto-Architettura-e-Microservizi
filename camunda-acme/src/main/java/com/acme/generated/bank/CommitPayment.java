
package com.acme.generated.bank;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
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
     * Recupera il valore della proprietà duration.
     * 
     */
    public int getDuration() {
        return duration;
    }

    /**
     * Imposta il valore della proprietà duration.
     * 
     */
    public void setDuration(int value) {
        this.duration = value;
    }

    /**
     * Recupera il valore della proprietà finalAmount.
     * 
     */
    public double getFinalAmount() {
        return finalAmount;
    }

    /**
     * Imposta il valore della proprietà finalAmount.
     * 
     */
    public void setFinalAmount(double value) {
        this.finalAmount = value;
    }

    /**
     * Recupera il valore della proprietà penalty.
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
     * Imposta il valore della proprietà penalty.
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
     * Recupera il valore della proprietà authToken.
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
     * Imposta il valore della proprietà authToken.
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

    /**
     * Recupera il valore della proprietà batteryLevel.
     * 
     */
    public int getBatteryLevel() {
        return batteryLevel;
    }

    /**
     * Imposta il valore della proprietà batteryLevel.
     * 
     */
    public void setBatteryLevel(int value) {
        this.batteryLevel = value;
    }

}
