package com.alofmethbin.jadawin;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Utils {
    private static final Pattern numberPrefix = Pattern.compile( "^\\d+_(.*)$");
    private static final Pattern numerical    = Pattern.compile( "^\\d+$");
    
    private Utils() {}
    
    public static String capitalise( String text) {
        return text.substring(0, 1).toUpperCase() + text.substring(1);
    }

    public static String columnAlign( String text) {
        Matcher m = numerical.matcher(text);
        return m.find() ? "right" : "left";
    }

    public static boolean compare( byte [] ba1, byte [] ba2) {
        if (ba1.length != ba2.length) {return false;}
        for (int i = 0; i < ba1.length; i++) {
            if (ba1[i] != ba2[i]) {return false;}
        }
        return true;
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

    public static byte [] load( File file) throws Exception {
        try (FileInputStream is = new FileInputStream( file)) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte [] buffer = new byte [10000];
            int read;
            while ((read = is.read(buffer)) > 0) {
                baos.write( buffer, 0, read);
            }
            return baos.toByteArray();
        }
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

    public static String read( File file) throws Exception {
        try (BufferedReader br = new BufferedReader( new FileReader( file))) {
            StringBuilder b = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                b.append( line);
                b.append( "\n");
            }
            return b.toString();
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

    public static void save( byte [] data, File file) throws Exception {
        try (FileOutputStream os = new FileOutputStream( file)) {
            os.write( data);
        }
    }

    public static String toPath( File ancestor, File file) throws IOException {
        String ancestorPath = ancestor.getCanonicalPath();
        String filePath     = file.getCanonicalPath();
        
        if ( filePath.startsWith( ancestorPath + "/") ) {
            return filePath.substring( ancestorPath.length());
        }
        
        throw new RuntimeException( "toPath file not in sink");
    }

    public static void write( String text, File file) throws Exception {
        try (FileWriter fw = new FileWriter( file)) {
            fw.write( text, 0, text.length());
        }
    }
}
