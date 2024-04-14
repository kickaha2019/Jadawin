package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Link;
import com.alofmethbin.jadawin.Page;
import com.alofmethbin.jadawin.Utils;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Year extends Events {
    private static Map<Integer,List<Article>> articlesByYear = null;

    @SuppressWarnings("null")
    private void findArticlesByYear( Article article) {
        if (article.getStyle() instanceof Year) {return;}
        
        LocalDate date = article.getDate();
        if (date != null) {
            Integer year = date.getYear();
            if (! articlesByYear.containsKey(year)) {
                articlesByYear.put( year, new ArrayList<>());
            }
            articlesByYear.get(year).add( article);
        }
        
        for (Page child: article.children()) {
            if (child instanceof Article) {
                findArticlesByYear( (Article) child);
            }
        }
    }

    @Override
    public String indexTitle(Page page) {
        LocalDate d = page.getDate();
        if (d != null) {
            return super.indexTitle( page) + 
                   " (" +
                   d.getMonth().toString().substring(0, 3) +
                   " " +
                   d.getDayOfMonth() +
                   Utils.formatOrdinal( d.getDayOfMonth()) + 
                   ")"; 
        } else {
            page.error( "Missing date for Year page");
            return super.indexTitle( page);
        }
    }

    @Override
    public void prepare( Article article) {
        synchronized ( Year.class ) {
            if (articlesByYear == null) {
                articlesByYear = new HashMap<>();
                Article root = article;
                while (root.parent() != null) {
                    root = root.parent();
                }
                findArticlesByYear( root);
            }
        }
        
        String title = article.getName();
        try {
            int year = Integer.parseInt( title);
            if (! title.equals( Integer.toString(year))) {
                article.error( "Expected year as title");
                return;
            }
            
            for (Page child: article.children()) {
                LocalDate d = child.getDate();
                if (d != null) {
                    if (d.getYear() != year) {
                        child.error( "Expected " + year + " date");
                    }
                } else {
                    child.error( "Expected date");
                }
            }
        
            if ( articlesByYear.containsKey( year) ) {
                for (Article other: articlesByYear.get(year)) {
                    article.addChild( new Link( other, null, other.getTitle()));
                }
            }
        } catch (NumberFormatException nfe) {
            article.error( "Expected year as title");
            return;
        }
    }    
}
