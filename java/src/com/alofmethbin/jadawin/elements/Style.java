package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.styles.StyleInterface;
import java.lang.reflect.Constructor;
import java.util.List;

public class Style extends Element {
    private StyleInterface style;
    
    public Style( Article article, List<String> lines) {
        super( article);
        
        try {
            Class clazz        = Class.forName("com.alofmethbin.jadawin.styles." + lines.get(0));
            Constructor constr = clazz.getConstructor( new Class [0]);
            style = (StyleInterface) constr.newInstance( new Object [0]);
        } catch (ClassNotFoundException cnfe) {
            error( "No such style: " + lines.get(0));
        } catch (Exception ex) {    
            error( "Unimplemented style: " + lines.get(0));
        }
    }

    public StyleInterface getStyle() {return style;}
    
    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }

    @Override
    public boolean isSpecial() {
        return true;
    }
}
