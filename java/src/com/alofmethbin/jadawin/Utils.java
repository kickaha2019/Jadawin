package com.alofmethbin.jadawin;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.time.LocalDate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Utils {
    private static Pattern numberPrefix = Pattern.compile( "^\\d+_(.*)$");
    private static Pattern numerical    = Pattern.compile( "^\\d+$");

    public static int load(File source, ByteArrayOutputStream sourceBuffer) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public static void save(ByteArrayOutputStream sourceBuffer, File sink) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public static boolean compare(ByteArrayOutputStream sourceBuffer, ByteArrayOutputStream sinkBuffer) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
    
    private Utils() {}
    
    public static String capitalise( String text) {
        return text.substring(0, 1).toUpperCase() + text.substring(1);
    }

    public static String columnAlign( String text) {
        Matcher m = numerical.matcher(text);
        return m.find() ? "right" : "left";
    }
    
    public static String format( LocalDate date) {
        return date.getDayOfWeek().toString() +
               ", " +
               formatSmall( date);
    }

    public static String formatOrdinal( int i) {
        if ((i > 3) && (i < 21)) {
            return "th";
        } else if ((i % 10) == 1) {
            return "st";
        } else if ((i % 10) == 2) {
            return "nd";
        } else if ((i % 10) == 3) {
            return "rd";
        } else {
            return "th";
        }
    }
    
    public static String formatSmall( LocalDate date) {
        return date.getDayOfMonth() + 
               formatOrdinal( date.getDayOfMonth()) +
               " " + 
               date.getMonth().toString() + 
               " " +
               date.getYear();
    }
    
    public static boolean isAbsoluteUrl( String url) {
        return url.startsWith( "http:")  || 
               url.startsWith( "https:") || 
               url.startsWith( "mailto:");
    }
    
    public static String prettify( String text) {
        Matcher m = numberPrefix.matcher(text);
        if ( m.find() ) {
            text = m.group(1);
        }
        
        if ( text.equals( text.toLowerCase()) ) {
            String [] split = text.split( "_");
            StringBuilder b = new StringBuilder();
            for (String part: split) {
                if (b.length() > 0) {b.append( " ");}
                b.append( Utils.capitalise( part));
            }
            return b.toString();
        } else {
            return text.replaceAll( "_", " ");
        }
    }

    public static String relativePath( File from, File to) {
        String [] fromParts = from.list();
        String [] toParts   = to.list();
        
        int diffFrom = 0;
        while ((diffFrom < fromParts.length) && 
               (diffFrom < toParts.length)   &&
               (fromParts[diffFrom].equals( toParts[diffFrom])) ) {
            diffFrom++;
        }
        
        StringBuilder b = new StringBuilder();
        for (int i = fromParts.length - 2; i >= diffFrom; i--) {
            b.append( "../");
        }
        
        for (int i = diffFrom; i < toParts.length; i++) {
            if (i > diffFrom) {b.append( "/");}
            b.append( toParts[i]);
        }
        
        return b.toString();
    }

    public static String toPath( File ancestor, File file) {
        String ancestorPath = ancestor.getAbsolutePath();
        String filePath     = file.getAbsolutePath();
        
        if ( filePath.startsWith( ancestorPath + "/") ) {
            return filePath.substring( ancestorPath.length());
        }
        
        throw new RuntimeException( "toPath file not in sink");
    }
}
