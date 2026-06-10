
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
     * Gets the value of the total property.
     * 
     */
    public double getTotal() {
        return total;
    }

    /**
     * Sets the value of the total property.
     * 
     */
    public void setTotal(double value) {
        this.total = value;
    }

    /**
     * Gets the value of the subtotal property.
     * 
     */
    public double getSubtotal() {
        return subtotal;
    }

    /**
     * Sets the value of the subtotal property.
     * 
     */
    public void setSubtotal(double value) {
        this.subtotal = value;
    }

    /**
     * Gets the value of the penalty property.
     * 
     */
    public double getPenalty() {
        return penalty;
    }

    /**
     * Sets the value of the penalty property.
     * 
     */
    public void setPenalty(double value) {
        this.penalty = value;
    }

    /**
     * Gets the value of the basePriceDistance property.
     * 
     */
    public double getBasePriceDistance() {
        return basePriceDistance;
    }

    /**
     * Sets the value of the basePriceDistance property.
     * 
     */
    public void setBasePriceDistance(double value) {
        this.basePriceDistance = value;
    }

    /**
     * Gets the value of the basePriceTime property.
     * 
     */
    public double getBasePriceTime() {
        return basePriceTime;
    }

    /**
     * Sets the value of the basePriceTime property.
     * 
     */
    public void setBasePriceTime(double value) {
        this.basePriceTime = value;
    }

}
