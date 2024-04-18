package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;

public class Document extends BaseStyle {

    @Override
    public String indexStyle(Article article) {
        return article.hasContent() ? "document" : super.indexStyle(article);
    }

    @Override
    public void prepare( Article article) {
        for (Page child: article.children()) {
            if ((! child.isStyled()) && (! child.hasChildren())) {
                child.setStyle( new TextIndex());
            }
        }
    }
}
