package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;

public class Hidden extends BaseStyle {

    @Override
    public boolean isIndex() {
        return false;
    }

    @Override
    public String postProcessHTML( Article article, String html) {
        html = super.postProcessHTML( article, html);
        return html.replaceAll( "", "");
    }

    @Override
    public void prepare( Article article) {
        if (article.parent() == null) {
            article.error( "Hidden page must be at root of website");
        }

        if ((article.parent() != null) && (article.parent().parent() != null)) {
            article.error( "Hidden page must be at root of website");
        }
    }
}
