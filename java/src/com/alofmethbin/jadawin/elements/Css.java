package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Css extends Element {
    private List<String> lines;
    
    public Css( Article article, List<String> lines) {
        super( article);
        this.lines = lines;
    }
}
