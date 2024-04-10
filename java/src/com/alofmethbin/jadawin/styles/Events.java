package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class Events extends BaseStyle {

    @Override
    public boolean isLeaf(Article article) {
        return false;
    }

    @Override
    public void sort( List<Page> children) {
        List<Page> noDates = new ArrayList<>();
        List<Page> dated   = new ArrayList<>();
        
        for (Page child: children) {
            if (child.getDate() == null) {
                noDates.add( child);
            } else {
                dated.add( child);
            }
        }
        
        if (noDates.size() > 1) {
            for (Page child: noDates) {
                child.error( "Expected date");
            }
        }
        
        dated.sort( new Comparator<>() {
            @Override
            public int compare( Page p0, Page p1) {
                return p0.getDate().compareTo( p1.getDate());
            }
        });
        
        children.clear();
        children.addAll( dated);
        children.addAll( noDates);
    }
}
