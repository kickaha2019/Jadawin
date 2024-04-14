package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Tag extends Element {
    private static Map<String,List<Tag>> tags = new HashMap<>();
    private String tag, origin;
    private int rendered = 0;
    
    public Tag( Article article, List<String> lines) {
        super( article);
        tag    = checkSpecialChars( lines.get(0));
        origin = tag.replaceAll( "\\W", "_").replaceAll( "__", "_");
        
        synchronized ( Tag.class ) {
            find(tag).add( this);
        }
        
        if ( origin.equals( "default") ) {
            error( "Tag name default not allowed");
        }
    }

    public void addOrigin( Article a) {
        article.addOrigin( origin, a);
    }

    public static void checkAllRendered() {
        for (List<Tag> list: tags.values()) {
            for (Tag t: list) {
                if ( t.hasError() ) {continue;}
                if (t.rendered < 1) {
                    t.article.error( "Location " + t.tag + " not rendered");
                } else if (t.rendered > 1) {
                    t.article.error( "Location " + t.tag + " multiply rendered");
                }
            }
        }
    }

    public static List<Tag> find( String tag) {
        List<Tag> list = tags.get(tag);
        if (list == null) {
            tags.put(tag, list = new ArrayList<>());
        }
        return list;
    }

    public LocalDate getDate() {
        return article.getDate();
    }

    public Image getIcon() {
        return article.getIcon();
    }
    
    public String getTitle() {
        return article.getTitle();
    }

    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }

    public void render() {
        this.rendered ++;
    }
}
