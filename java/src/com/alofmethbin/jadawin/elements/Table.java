package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Table extends Element {
    private List<String> columns = new ArrayList<>();
    private List<List<Text>> rows = new ArrayList<>();
    
    public Table( Article article, List<String> lines) throws IOException {
        super( article);
        
        for (String column: divide( lines.get(0))) {
            columns.add( checkLabel( column));
        }
        
        for (int i = 1; i < lines.size(); i++) {
            List<Text> row = new ArrayList<>();
            rows.add( row);
            
            for (String value: divide( lines.get(i))) {
                row.add( new Text( article, value));
            }
        }
    }
    
    private String [] divide( String line) {
        line = line.trim();
        if ( line.startsWith( "|") ) {line = line.substring(1);}
        if ( line.endsWith( "|") ) {line = line.substring( 0, line.length() - 1);}
        return line.split( "\\|");
    }

    @Override
    public int lineCount() {
        return 5 + rows.size();
    }

    @Override
    public void prepare() {
        for (List<Text> row: rows) {
            for (Text text: row) {text.prepare();} 
        }
    }
}
