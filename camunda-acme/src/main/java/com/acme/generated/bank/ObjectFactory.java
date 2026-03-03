
package com.acme.generated.bank;

import jakarta.xml.bind.annotation.XmlRegistry;


/**
 * This object contains factory methods for each 
 * Java content interface and Java element interface 
 * generated in the com.acme.generated.bank package. 
 * <p>An ObjectFactory allows you to programatically 
 * construct new instances of the Java representation 
 * for XML content. The Java representation of XML 
 * content can consist of schema derived interfaces 
 * and classes representing the binding of schema 
 * type definitions, element declarations and model 
 * groups.  Factory methods for each of these are 
 * provided in this class.
 * 
 */
@XmlRegistry
public class ObjectFactory {


    /**
     * Create a new ObjectFactory that can be used to create new instances of schema derived classes for package: com.acme.generated.bank
     * 
     */
    public ObjectFactory() {
    }

    /**
     * Create an instance of {@link PreAuthorize }
     * 
     */
    public PreAuthorize createPreAuthorize() {
        return new PreAuthorize();
    }

    /**
     * Create an instance of {@link PreAuthorizeResponse }
     * 
     */
    public PreAuthorizeResponse createPreAuthorizeResponse() {
        return new PreAuthorizeResponse();
    }

    /**
     * Create an instance of {@link CommitPayment }
     * 
     */
    public CommitPayment createCommitPayment() {
        return new CommitPayment();
    }

    /**
     * Create an instance of {@link CommitPaymentResponse }
     * 
     */
    public CommitPaymentResponse createCommitPaymentResponse() {
        return new CommitPaymentResponse();
    }

    /**
     * Create an instance of {@link CommitPenalty }
     * 
     */
    public CommitPenalty createCommitPenalty() {
        return new CommitPenalty();
    }

    /**
     * Create an instance of {@link CommitPenaltyResponse }
     * 
     */
    public CommitPenaltyResponse createCommitPenaltyResponse() {
        return new CommitPenaltyResponse();
    }

    /**
     * Create an instance of {@link CancelAuth }
     * 
     */
    public CancelAuth createCancelAuth() {
        return new CancelAuth();
    }

}
