package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.elements.Tag;
import com.alofmethbin.jadawin.styles.StyleInterface;
import java.io.File;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class Link implements Page {
    private final Article article;
    private final Tag tag;
    private final String title;
    
    public Link( Article article, Tag tag, String title) {
        this.article = article;
        this.tag     = tag;
        this.title   = title;
    }
    
    @Override
    public void error( String msg) {
        article.error( msg);
    }

    @Override
    public LocalDate getDate() {
        return article.getDate();
    }

    @Override
    public boolean hasChildren() {
        return false;
    }

    @Override
    public Image getIcon() {
        return article.getIcon();
    }

    @Override
    public String getName() {
        return article.getName();
    }

    @Override
    public File getSinkFile() {
        return article.getSinkFile();
    }

    @Override
    public String getTitle() {
        return article.getTitle();
    }

    @Override
    public boolean isOffPage() {
        return false;
    }

    @Override
    public boolean isStyled() {
        return article.isStyled();
    }

    @Override
    public void prepare() {
    }

    @Override
    public void setStyle( StyleInterface style) {
        article.setStyle( style);
    }
}
