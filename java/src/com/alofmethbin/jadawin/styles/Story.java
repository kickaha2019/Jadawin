package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import java.util.List;

public class Story extends Events {
    class Navigation extends BaseStyle {
        private final Article before;
        private final Article after;

        Navigation( Article before, Article after) {
            this.before = before;
            this.after  = after;
        }
    }
    
    @Override
    public boolean isLeaf(Article article) {
        return true;
    }

    @Override
    public void prepare( Article article) {
        boolean allArticles = true;
        for (Page p: article.children()) {
            if (! (p instanceof Article)) {allArticles = false;}
        }
        
        if (! allArticles) {
            article.error( "Not all children articles");
            return;
        }
        
        Article last2 = null;
        Article last1 = article.hasContent() ? article : null;
        for (Page p: article.children()) {
            Article child = (Article) p;
            if (last1 != null) {
                last1.setStyle( new Navigation( last2, child));
            }
            
            last2 = last1;
            last1 = child;
        }
        
        last1.setStyle( new Navigation( last2, null));
    }
}
