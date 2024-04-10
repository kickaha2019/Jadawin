package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Code extends Element {
    private List<String> lines;
    
    public Code( Article article, List<String> lines) {
        super( article);
        
        int indent = 100;
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).replaceAll( "\t", "  ");
            for (int j = 0; (j < line.length()) && (j < indent); j++) {
               if (! Character.isWhitespace( line.charAt(j))) {
                   indent = j;
               } 
            }
            lines.set( i, line);
        }
        
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).substring( indent);
            if ( line.isBlank() ) {line = "&nbsp;";}
            lines.set( i, line);
        }

        this.lines = lines;
    }

    private String encodeHtmlChars( String text) {
        return text.replaceAll( "&", "&amp;")
                   .replaceAll( "<", "&lt;")
                   .replaceAll( ">", "&gt;");
    }

    @Override
    public int lineCount() {
        return 100;
    }
}
