package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import java.util.List;

public interface StyleInterface {
    public String indexStyle(Article aThis);
    public String indexTitle( Page page);
    public boolean isIndex();
    public boolean isLeaf( Article article);
    public String postProcessHTML( Article article, String html);
    public void prepare(Article aThis);
    public void sort(List<Page> children);
}
