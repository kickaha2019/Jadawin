package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.styles.StyleInterface;
import java.io.File;
import java.util.List;

public interface Page {
    public void error( String msg);
    public java.time.LocalDate getDate();
    public Image getIcon();
    public String getName();
    public File getSinkFile();
    public String getTitle();
    public boolean hasChildren();
    public boolean isOffPage();
    public boolean isStyled();
    public void prepare();
    public void setStyle( StyleInterface style);
}
