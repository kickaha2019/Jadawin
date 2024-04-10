package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Heading extends Element {
    private String text;

    public Heading( Article article, List<String> lines) {
        super( article);
        text  = lines.get(0);
    }

    @Override
    public boolean isMultiline() {
        return false;
    }
}
