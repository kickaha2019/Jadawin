package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Html extends Element {
    private List<String> lines;
    
    public Html( Article article, List<String> lines) {
        super( article);
        this.lines = lines;
    }

    @Override
    public int lineCount() {
        return 100;
    }
}
