package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public abstract class Element {
    protected Article article;
    private boolean error = false;
    private int index = -1;
    private Matcher matcher;
    private static Map<String,Map<String,Integer>> lastIndexes = new HashMap<>();
    
//    public static String specialChars = "[\"<>`\\*]";

    Element( Article article) {
        this.article = article;
        synchronized ( Element.class ) {
            String file = article.getSinkFile().getAbsolutePath();
            Map<String,Integer> lastIndex = lastIndexes.get( file);
            if (lastIndex == null) {
                lastIndexes.put( file, lastIndex = new HashMap<>());
            }
            
            Integer last = lastIndex.get( typeName());
            if (last == null) {
                lastIndex.put( typeName(), index = 1);
            } else {
                lastIndex.put( typeName(), index = last + 1);
            }
        }
    }

    public void allowForInset() {
        error( "Inset not followed by Text");
    }
    
    protected final String checkLabel( String toCheck) {
        String text = toCheck.replaceAll( "[\\*\\[\\]<>`]", "");
        if (! text.equals(toCheck)) {
            error( "Unexpected characters in " + toCheck);
        }
        return text;
    }
    
    protected final String checkSpecialChars( String toCheck) {
        String text = toCheck.replaceAll( "[\"<>`\\*]", "");
        if (! text.equals(toCheck)) {
            // error( "Bad characters in " + typeName() + ": " + toCheck);
            error( "Bad characters in " + typeName().toLowerCase());
        }
        return text;
    }
    
    public final void error( String msg) {
        article.error( msg);
        error = true;
    }
    
    public Image getImage() {
        return null;
    }

    protected final int getIndex() {return index;}

    protected String group( int i) {
        return matcher.group(i);
    }
    
    public final boolean hasError() {
        return error;
    }

    public boolean ignoreError(String msg) {
        return false;
    }

    public boolean isContent() {
        return true;
    }

    public boolean isInset() {
        return false;
    }

    public boolean isMultiline() {
        return true;
    }

    public boolean isOverlay() {
        return false;
    }

    public boolean isSpecial() {
        return false;
    }

    public boolean isWide() {
        return false;
    }

    public int lineCount() {
        return 0;
    }

    protected boolean match( Pattern pattern, String text) {
        matcher = pattern.matcher(text);
        return matcher.find();
    }

    public void prepare() {
    }
    
    public String postProcessHTML(String html) {
        return html;
    }

    public static java.util.List<String> toList( String line) {
        java.util.List<String> list = new ArrayList<>();
        list.add( line);
        return list;
    }
    
    public final String typeName() {
        return getClass().getSimpleName();
    }
    
    public static void warn( String msg) {
        System.err.println( "!!! " + msg);
    }
}
