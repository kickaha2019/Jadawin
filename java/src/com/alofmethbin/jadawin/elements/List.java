package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.io.IOException;
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class List extends Element {
    private java.util.List<Text> points = new ArrayList<>();
    private java.util.List<String> keys = new ArrayList<>();
    private java.util.List<Text> values = new ArrayList<>();
    private static Pattern crack = Pattern.compile( "^([^\\|]*)\\|(.*)$");
    
    public List( Article article, java.util.List<String> lines) throws IOException {
        super( article);
        
        boolean isTable = false;
        
        for (String line: lines) {
            Matcher m = crack.matcher(line);
            if ( m.find() ) {isTable = true; break;}
        }        
        
        for (String line: lines) {
            Matcher m = crack.matcher(line);
            if ( m.find() ) {
                keys.add( checkLabel( m.group(1)));
                values.add( new Text( article, m.group(2)));
            } else if (! line.isBlank()) {
                if ( isTable ) {
                    keys.add( checkLabel( line));
                    values.add( new Text( article, ""));
                } else {
                    points.add( new Text( article, line));
                }
            }
        }
        
        if ( keys.isEmpty() ) {
            if ( points.isEmpty() ) {
                error( "Empty list");
            }
        }
    }

    @Override
    public int lineCount() {
        return 3 + keys.size();
    }

    @Override
    public void prepare() {
        for (Text text: values) {text.prepare();}
        for (Text text: points) {text.prepare();}
    }
}
