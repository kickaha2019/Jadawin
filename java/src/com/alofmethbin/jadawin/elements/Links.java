package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Link;
import java.time.LocalDate;
import java.util.List;

public class Links extends Element {
    private String tag;
    
    public Links( Article article, List<String> lines) {
        super( article);
        tag = lines.get(0);
    }

    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }

    @Override
    public void prepare() {
        List<Tag> tags = Tag.find( tag);
        if ( tags.isEmpty() ) {
            error( "Unknown tag: " + tag);
            return;
        }
        
        LocalDate now = article.now();
        for (Tag t: tags) {
            t.render();
            if (t.getDate() != null) {
                if ( t.getDate().isAfter(now) ) {continue;}
            }
            article.addChild( new Link( article, t, t.getTitle()));
            t.addOrigin( article);
        }
    }
}
