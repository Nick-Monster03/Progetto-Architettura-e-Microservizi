
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
 *         &lt;element name="total" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="subtotal" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="penalty" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="basePriceDistance" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
 *         &lt;element name="basePriceTime" type="{http://www.w3.org/2001/XMLSchema}double"/&gt;
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
    "total",
    "subtotal",
    "penalty",
    "basePriceDistance",
    "basePriceTime"
})
@XmlRootElement(name = "calculateCostResponse")
public class CalculateCostResponse {

    protected double total;
    protected double subtotal;
    protected double penalty;
    protected double basePriceDistance;
    protected double basePriceTime;

    /**
     * Recupera il valore della proprietà total.
     * 
     */
    public double getTotal() {
        return total;
    }

    /**
     * Imposta il valore della proprietà total.
     * 
     */
    public void setTotal(double value) {
        this.total = value;
    }

    /**
     * Recupera il valore della proprietà subtotal.
     * 
     */
    public double getSubtotal() {
        return subtotal;
    }

    /**
     * Imposta il valore della proprietà subtotal.
     * 
     */
    public void setSubtotal(double value) {
        this.subtotal = value;
    }

    /**
     * Recupera il valore della proprietà penalty.
     * 
     */
    public double getPenalty() {
        return penalty;
    }

    /**
     * Imposta il valore della proprietà penalty.
     * 
     */
    public void setPenalty(double value) {
        this.penalty = value;
    }

    /**
     * Recupera il valore della proprietà basePriceDistance.
     * 
     */
    public double getBasePriceDistance() {
        return basePriceDistance;
    }

    /**
     * Imposta il valore della proprietà basePriceDistance.
     * 
     */
    public void setBasePriceDistance(double value) {
        this.basePriceDistance = value;
    }

    /**
     * Recupera il valore della proprietà basePriceTime.
     * 
     */
    public double getBasePriceTime() {
        return basePriceTime;
    }

    /**
     * Imposta il valore della proprietà basePriceTime.
     * 
     */
    public void setBasePriceTime(double value) {
        this.basePriceTime = value;
    }

}
