
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
 *         &lt;element name="isRiservation" type="{http://www.w3.org/2001/XMLSchema}boolean"/&gt;
 *         &lt;element name="amount" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="userId" type="{http://www.w3.org/2001/XMLSchema}string"/&gt;
 *         &lt;element name="cardNumber" type="{http://www.w3.org/2001/XMLSchema}string"/&gt;
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
    "isRiservation",
    "amount",
    "userId",
    "cardNumber"
})
@XmlRootElement(name = "preAuthorize")
public class PreAuthorize {

    protected boolean isRiservation;
    protected double amount;
    @XmlElement(required = true)
    protected String userId;
    @XmlElement(required = true)
    protected String cardNumber;

    /**
     * Recupera il valore della proprietà isRiservation.
     * 
     */
    public boolean isIsRiservation() {
        return isRiservation;
    }

    /**
     * Imposta il valore della proprietà isRiservation.
     * 
     */
    public void setIsRiservation(boolean value) {
        this.isRiservation = value;
    }

    /**
     * Recupera il valore della proprietà amount.
     * 
     */
    public double getAmount() {
        return amount;
    }

    /**
     * Imposta il valore della proprietà amount.
     * 
     */
    public void setAmount(double value) {
        this.amount = value;
    }

    /**
     * Recupera il valore della proprietà userId.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getUserId() {
        return userId;
    }

    /**
     * Imposta il valore della proprietà userId.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setUserId(String value) {
        this.userId = value;
    }

    /**
     * Recupera il valore della proprietà cardNumber.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getCardNumber() {
        return cardNumber;
    }

    /**
     * Imposta il valore della proprietà cardNumber.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setCardNumber(String value) {
        this.cardNumber = value;
    }

}
