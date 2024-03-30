package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Image;

public interface Page {
    public void error( String msg);
    public java.time.LocalDate getDate();
    public boolean hasChildren();
    public Image getIcon();
    public boolean isOffPage();
}
