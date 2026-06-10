package com.acme.delegates;

public class extractTagValue {

    public extractTagValue() {
    }
    
    
    public static String extractTagValue(String xml, String tag) {
        if (xml == null || xml.isEmpty()) {
            return null;
        }
        
        // Cerca apertura tag (con o senza attributi)
        String openTagPattern = "<" + tag;
        int start = xml.indexOf(openTagPattern);
        
        if (start == -1) {
            return null;
        }
        
        // Trova la chiusura del tag di apertura (il ">")
        int tagCloseIndex = xml.indexOf(">", start);
        if (tagCloseIndex == -1) {
            return null;
        }
        
        // Cerca il tag di chiusura
        String closeTag = "</" + tag + ">";
        int end = xml.indexOf(closeTag, tagCloseIndex);
        
        if (end == -1) {
            return null;
        }
        
        // Estrae il contenuto tra > e </tag>
        String value = xml.substring(tagCloseIndex + 1, end).trim();
        
        return value.isEmpty() ? null : value;
    }
    
    /**
     * Estrae e converte in Double (sicuro, ritorna 0.0 se errore)
     */
    public static Double extractDoubleValue(String xml, String tag) {
        String value = extractTagValue(xml, tag);
        if (value == null || value.isEmpty()) {
            return 0.0;
        }
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
    
    /**
     * Estrae e converte in Integer (sicuro, ritorna 0 se errore)
     */
    public static Integer extractIntValue(String xml, String tag) {
        String value = extractTagValue(xml, tag);
        if (value == null || value.isEmpty()) {
            return 0;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

}
