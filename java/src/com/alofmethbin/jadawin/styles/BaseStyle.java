package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import java.util.List;

public class BaseStyle implements Style {

    @Override
    public boolean isLeaf(Article aThis) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public String postProcessHTML(String html) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void sort(List<Page> children) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void prepare(Article aThis) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

}
