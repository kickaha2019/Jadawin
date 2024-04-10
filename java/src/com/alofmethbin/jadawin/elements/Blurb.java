package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Blurb extends Element {
    private String text;
    
    public Blurb( Article article, List<String> lines) {
        super( article);
        
        StringBuilder b = new StringBuilder();
        for (String line: lines) {
            if (b.length() > 0) {b.append( " ");}
            b.append( line);
        }
        
        text = checkSpecialChars( b.toString());
        
        if (text.length() > 50) {
            error( "Blurb too long");
        }
    }

    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isSpecial() {
        return true;
    }
    
    public String text() {
        return text;
    }
}
