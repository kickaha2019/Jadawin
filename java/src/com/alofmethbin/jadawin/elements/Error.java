package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.ArrayList;
import java.util.List;

public class Error extends Element {
    private static List<Error> tests = new ArrayList<>();
    private boolean matched = false;
    private String title, match;
    
    public Error( Article article, List<String> lines) {
        super( article);
        synchronized ( Error.class ) {
            tests.add( this);
        }
        
        if (lines.size() != 2) {
            error( "Bad error directive");
        } else {
            title = lines.get(0);
            match = lines.get(1);
        }
    }

    @Override
    public boolean ignoreError(String msg) {
        if ( matched ) {return false;}
        if ( msg.equals( match) ) {
            return matched = true;
        } else {
            return false;
        }
    }

    @Override
    public boolean isContent() {
        return false;
    }
    
    public static int numberOfTests() {
        return tests.size();
    }

    public static void reportErrors() {
        for (Error e: tests) {
            e.reportUnmatched();
        }
    }

    private void reportUnmatched() {
        if (! matched) {
            error( "Not caught: " + title);
        }
    }
}
