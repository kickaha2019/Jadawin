package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Table extends Element {
    private List<String> columns = new ArrayList<>();
    private List<List<Text>> rows = new ArrayList<>();
    
    public Table( Article article, List<String> lines) throws IOException {
        super( article);
        
        for (String column: lines.get(0).split( "|")) {
            columns.add( checkLabel( column));
        }
        
        for (int i = 1; i < lines.size(); i++) {
            List<Text> row = new ArrayList<>();
            rows.add( row);
            
            for (String value: lines.get(i).split( "|")) {
                row.add( new Text( article, value));
            }
        }
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
