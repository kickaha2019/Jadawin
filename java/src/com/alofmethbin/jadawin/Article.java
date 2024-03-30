package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Blurb;
import com.alofmethbin.jadawin.elements.Date;
import com.alofmethbin.jadawin.elements.Element;
import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.elements.Tag;
import com.alofmethbin.jadawin.elements.Title;
import com.alofmethbin.jadawin.styles.BaseStyle;
import com.alofmethbin.jadawin.styles.Story;
import com.alofmethbin.jadawin.styles.Style;
import java.io.File;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class Article implements Page {
    private List<Page> children = new ArrayList<>();
    private List<Element> content = new ArrayList<>();
    private Map<String,Element> specials = new HashMap<>();
    private Style style;
    private boolean childrenSorted = true;
    private final Article parent;
    private final File file;
    private Compiler compiler;
    private static Style baseStyle = new BaseStyle();
    
    class Origin {
        Origin( String n, Article a) {
            name    = n;
            article = a;
        }
        Article article;
        String name;
    }
    private List<Origin> origins = new ArrayList<>();
    
    public Article( Compiler compiler, Article parent, File file) {
        this.compiler = compiler;
        this.parent   = parent;
        this.file     = file;
    }
    
    public Page addChild( Page child) {
        childrenSorted = false;
        children.add( child);
        return child;
    }
    
    public void addContent( Element element, boolean multiline) {
        if (! element.hasError()) {
            if (multiline && (! element.isMultiline())) {
                error( element.typeName() + " takes only one line");
            } else if ( element.isSpecial() ) {
                if ( specials.containsKey( element.typeName())) {
                    error( "Duplicate " + element.typeName() + " definition");
                } else {
                    specials.put( element.typeName(), element);
                }
            } else {
                content.add( element);
            }
        }
    }

    public void addOrigin( String tag, Article parent) {
        origins.add( new Origin( tag, parent));
    }
    
    public List<Reference> breadcrumbs() {
        List<Reference> refs = new ArrayList<>();
        Article page = this;
        while (page != null) {
            refs.add( 0, new Reference( relativePath( file, page.getFile()), 
                                        prettify( page.getTitle())));
        }
        return refs;
    }
    
    public List<Page> children() {
        if (! this.childrenSorted) {
            getStyle().sort( children);
            childrenSorted = true;
        }
        return new ArrayList( children);
    }
    
    public void discardFutureChildren() {
        List old = children;
        children = new ArrayList<>();
        LocalDate now = LocalDate.now();
        
        for (Page child: children) {
            LocalDate d = child.getDate();
            if ((d == null) || (! d.isAfter( now))) {
                children.add( child);
            }
        }
    }
    
    public void error( String msg) {
        for (Element e: content) {
            if ( e.ignoreError( msg) ) {return;}
        }
        compiler.error( compiler.toPath( this.file).replace( ".html", ".txt"), msg);
    }
    
    public String getBlurb() {
        Blurb blurb;
        if ((blurb = (Blurb) specials.get( "Blurb")) != null) {
            return blurb.text();
        }
        return null;
    }

    public java.time.LocalDate getDate() {
        Date date;
        if ((date = (Date) specials.get( "Date")) != null) {
            return date.date();
        }
        return null;
    }

    public File getFile() {return file;}
    
    public Image getIcon() {
        Image icon;
        if ((icon = (Image) specials.get( "Icon")) != null) {
            return icon;
        }
        
        for (Element e: content) {
            if ((icon = e.getImage()) != null) {
                return icon;
            }
        }
        
        for (Page p: children()) {
            if ((icon = p.getIcon()) != null) {
                return icon;
            }
        }
        
        return null;
    }
    
    public String getName() {
        if ( file.getName().equals( "index.html") ) {
            return file.getParentFile().getName();
        } else {
            return file.getName().replace( ".html", "");
        }
    }
    
    public String getPageTitle() {
        if (parent != null) {
            return prettify( getTitle());
        } else {
            return null;
        }
    }
    
    public Style getStyle() {
        if (style != null) {
            return style;
        } else if ( isStyled() ) {
            return (Style) specials.get( "Style");
        } else {
            return baseStyle;
        }
    }

    public List<Tag> getTags() {
        List<Tag> tags = new ArrayList<>();
        for (Element e: content) {
            if (e instanceof Tag) {
                tags.add( (Tag) e);
            }
        }
        return tags;
    }
    
    public String getTitle() {
        Title title;
        if ((title = (Title) specials.get( "Title")) != null) {
            return title.text();
        }
        
        return getName();
    }
    
    public boolean hasChildren() {
        return ! children.isEmpty();
    }
    
    public boolean hasContent() {
        for (Element e: content) {
            if ( e.isContent() ) {return true;}
        }
        return false;
    }
    
    public boolean hasGrandChildren() {
        for (Page child: children) {
            if ( child.hasChildren() ) {return true;}
        }
        return false;
    }
    
    public boolean isLeaf() {
        return getStyle().isLeaf( this);
    }
    
    public boolean isOffPage() {
        return false;
    }

    private boolean isStory() {
        return hasContent() && (getDate() != null) && (! hasGrandChildren());
    }

    private boolean isStyled() {
        return specials.get( "Style") != null;
    }
    
    public boolean isWide() {
        for (Element e: content) {
            if ( e.isWide() ) {return true;}
        }
        return false;
    }

    private void overrideStyle( Style style) {
        this.style          = style;
        this.childrenSorted = false;
    }
    
    public void prepare() {
        if ((! isStyled()) && isStory()) {
            overrideStyle( new Story());
        }
        getStyle().prepare( this);
        
        for (int i = 0; i < content.size(); i++) {
            content.get(i).prepare( this, content.subList( (i+1), content.size()));
        }
    }
    
    public String postProcessHTML( String html) {
        html = getStyle().postProcessHTML( html);
        for (Element e: content) {
            html = e.postProcessHTML( html);
        }
        return html;
    }
    
    public String prettify( String text) {
        return compiler.prettify( text);
    }
    
    public String relativePath( File from, File to) {
        return compiler.relativePath( from, to);
    }
    
    
}
