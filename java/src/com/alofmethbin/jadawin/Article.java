package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Blurb;
import com.alofmethbin.jadawin.elements.Date;
import com.alofmethbin.jadawin.elements.Element;
import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.elements.Style;
import com.alofmethbin.jadawin.elements.Tag;
import com.alofmethbin.jadawin.elements.Title;
import com.alofmethbin.jadawin.styles.BaseStyle;
import com.alofmethbin.jadawin.styles.Story;
import java.io.File;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.alofmethbin.jadawin.styles.StyleInterface;
import java.io.IOException;

public final class Article implements Page {
    private List<Page> children = new ArrayList<>();
    private List<Element> content = new ArrayList<>();
    private Map<String,Element> specials = new HashMap<>();
    private StyleInterface style;
    private boolean childrenSorted = true;
    private final Article parent;
    private final String path;
    private Compiler compiler;
    private static StyleInterface baseStyle = new BaseStyle();
    
    class Origin {
        Origin( String n, Article a) {
            name    = n;
            article = a;
        }
        Article article;
        String name;
    }
    private List<Origin> origins = new ArrayList<>();
    
    public Article( Compiler compiler, Article parent, String path) {
        this.compiler = compiler;
        this.parent   = parent;
        this.path     = path;
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
        File file    = getSinkFile();
        
        while (page != null) {
            
            refs.add( 0, new Reference( Utils.relativePath( file, page.getSinkFile()), 
                                        Utils.prettify( page.getTitle())));
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
        List<Page> old = children;
        children       = new ArrayList<>();
        
        for (Page child: old) {
            LocalDate d = child.getDate();
            if ((d == null) || (! d.isAfter( now()))) {
                children.add( child);
            }
        }
    }
    
    @Override
    public void error( String msg) {
        for (Element e: content) {
            if ( e.ignoreError( msg) ) {return;}
        }
        compiler.error( path, msg);
    }
    
    public String getBlurb() {
        Blurb blurb;
        if ((blurb = (Blurb) specials.get( "Blurb")) != null) {
            return blurb.text();
        }
        return null;
    }

    @Override
    public java.time.LocalDate getDate() {
        Date date;
        if ((date = (Date) specials.get( "Date")) != null) {
            return date.getDate();
        }
        return null;
    }
    
    @Override
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
        File file = getSinkFile();
        if ( file.getName().equals( "index.html") ) {
            return file.getParentFile().getName();
        } else {
            return file.getName().replace( ".html", "");
        }
    }
    
    public String getPageTitle() {
        if (parent != null) {
            return Utils.prettify( getTitle());
        } else {
            return null;
        }
    }

    public String getRootURL() {
        return compiler.getRootURL();
    }

    @Override
    public File getSinkFile() {
        return compiler.toSinkFile( path.replace( ".txt", ".html"));
    }
    
    public StyleInterface getStyle() {
        if (style != null) {
            return style;
        } else if ( isStyled() ) {
            return ((Style) specials.get( "Style")).getStyle();
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
    
    @Override
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
    
    @Override
    public boolean isOffPage() {
        return false;
    }

    private boolean isStory() {
        return hasContent() && (getDate() != null) && (! hasGrandChildren());
    }

    public boolean isStyled() {
        return (specials.get( "Style") != null);
    }
    
    public boolean isWide() {
        for (Element e: content) {
            if ( e.isWide() ) {return true;}
        }
        return false;
    }

    public Page lookupPage( String url) {
        return compiler.lookupPage( this, url, url);
    }

    public LocalDate now() {
        return compiler.now();
    }

    private void overrideStyle( StyleInterface style) {
        this.style          = style;
        this.childrenSorted = false;
    }
    
    @Override
    public void prepare() {
        try {
            if ((! isStyled()) && isStory()) {
                overrideStyle( new Story());
            }
            getStyle().prepare( this);

            for (int i = 0; i < content.size(); i++) {
                content.get(i).prepare();
                if ( content.get(i).isInset() ) {
                    if (i < content.size() - 1) {
                        content.get(i+1).allowForInset();
                    } else {
                        error( "Inset cannot be final directive");
                    }
                }
            }
        } catch (Exception bang) {
            error( bang.getMessage());
            //throw bang;
        }
        
        List<Page> subArticles = new ArrayList<>();
        for (Page child: children) {
            if (child instanceof Article) {
                subArticles.add( child);
            }
        }
        
        for (Page child: subArticles) {
            child.prepare();
        }
    }

    public Article parent() {
        return parent;
    }
    
    public String postProcessHTML( String html) {
        html = getStyle().postProcessHTML( this, html);
        for (Element e: content) {
            html = e.postProcessHTML( html);
        }
        return html;
    }

    public void record( File sink) {
        compiler.record( sink);
    }

    @Override
    public void setStyle( StyleInterface style) {
        this.style = style;
    }

    public void spellCheck(String text) {
        compiler.spellCheck( this, text);
    }

    public String toPath( File file) throws IOException {
        return compiler.toPath( file);
    }

    public File toSinkFile( String relpath) {
        File file = getSinkFile();
        return new File( file.getParentFile(), relpath);
    }

    public File toSourceFile( String relpath) {
        File file = compiler.toSourceFile( path);
        return new File( file.getParentFile(), relpath);
    }
}
