package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import com.alofmethbin.jadawin.Utils;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class BaseStyle implements StyleInterface {
    private Matcher matcher;
    private static Pattern numericStart = Pattern.compile( "^(\\d+)");

    private String group( int i) {
        return matcher.group(i);
    }

    @Override
    public String indexStyle(Article aThis) {
        return "";
    }

    @Override
    public String indexTitle( Page page) {
        return Utils.prettify( page.getTitle());
    }

    @Override
    public boolean isIndex() {
        return true;
    }

    @Override
    public boolean isLeaf( Article article) {
        return article.hasContent();
    }

    private boolean match( Pattern pattern, String text) {
        matcher = pattern.matcher(text);
        return matcher.find();
    }

    @Override
    public void prepare( Article article) {
    }

    @Override
    public String postProcessHTML( Article article, String html) {
        return html;
    }

    @Override
    public void sort( List<Page> children) {
        children.sort( new Comparator<>() {
            @Override
            public int compare( Page p0, Page p1) {
                String n0 = p0.getName();
                String n1 = p1.getName();
                
                int i0 = -1;
                if ( match( numericStart, n0) ) {i0 = Integer.parseInt( group(1));}
                int i1 = -1;
                if ( match( numericStart, n1) ) {i1 = Integer.parseInt( group(1));}
                
                if ((i0 >= 0) && (i1 >= 0)) {return i0 - i1;}
                
                return Utils.prettify( p0.getTitle()).compareTo( Utils.prettify( p1.getTitle()));
            }
        });
    }
}
