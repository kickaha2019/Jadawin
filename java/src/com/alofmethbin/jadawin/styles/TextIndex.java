package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;

public class TextIndex extends BaseStyle {

    @Override
    public String indexStyle(Article article) {
        return article.hasContent() ? "document" : super.indexStyle(article);
    }
}
