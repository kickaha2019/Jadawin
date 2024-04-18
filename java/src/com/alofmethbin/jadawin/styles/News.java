package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Link;
import com.alofmethbin.jadawin.Page;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class News extends BaseStyle {
    private void findDatedArticles( Page page, List<Page> found) {
      if (page instanceof Link) {return;}
      Article article = (Article) page;
      
      if (article.hasDate() && article.isLeaf()) {
        found.add( article);
      }

      if (! article.isLeaf()) {
        for (Page child: article.children()) {
          findDatedArticles( child, found);
        }
      }
    }

    @Override
    public void prepare(Article article) {
        if ( article.hasDate() ) {
            article.error( "News style article must not be dated");
        }

        if ( article.hasChildren()) {
            article.error( "News style article must not have children");
        }

        List<Page> dated = new ArrayList<>();
        findDatedArticles( article, dated);
        sort( dated);
        
        for (int i = Math.min( 29, dated.size() - 1); i >= 0; i--) {
            article.addChild( dated.get(i));
        }
    }

    @Override
    public void sort( List<Page> children) {
        children.sort( new Comparator<>() {
            @Override
            public int compare( Page p0, Page p1) {
                return p1.getDate().compareTo( p0.getDate());
            }
        });
    }
}
