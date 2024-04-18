package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;

public class Title extends Element {
    private String text;
    
    public Title( Article article, List<String> lines) {
        super( article);
        text = checkSpecialChars( lines.get(0));
    }

    @Override
    public boolean isMultiline() {
        return false;
    }

    public String text() {
        return text;
    }
}
