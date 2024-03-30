package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import java.util.List;

public interface Style {
    public boolean isLeaf(Article aThis);
    public String postProcessHTML(String html);
    public void sort(List<Page> children);

    public void prepare(Article aThis);
}
