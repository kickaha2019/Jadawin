package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Page;
import com.alofmethbin.jadawin.Utils;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Text extends Element {
    private int lineCount = 0, minLines = 0;
    private Map<String,List<String>> name2Urls = new HashMap<>();
    private List<List<Segment>> paragraphs = new ArrayList<>();
    private Matcher matcher;
    
    private static Pattern linkTargetEnd      = Pattern.compile( "^([^\\)]*)\\)(.*)$");
    private static Pattern linkTextEnd        = Pattern.compile( "^([^\\]]*)\\](.*)$");
    private static Pattern nextCodeChar       = Pattern.compile( "^([^`]*)`(.*)$");
    private static Pattern nextEmphasizedChar = Pattern.compile( "^([^\\*]*)\\*(.*)$");
    private static Pattern nextSpecialChar    = Pattern.compile( "^([^`\\*\\[]*)([`\\*\\[])(.*)$");

    interface Segment {
        public void prepare();
    }
    
    class Emphasized implements Segment {
        private final String text;
        
        Emphasized( String text) {
            this.text = text.replaceAll( "<", "&lt;").replaceAll( ">", "&gt;");
        }
        
        public void prepare() {
            article.spellCheck( text);
        }
    }
    
    class Linkage implements Segment {
        private final String text;
        private String url;
        
        Linkage( String text, String url) {
            this.text = text.replaceAll( "<", "&lt;").replaceAll( ">", "&gt;");
            this.url  = url;
            
            if (url != null) {
                synchronized ( Text.class ) {
                    List<String> urls = name2Urls.get( text);
                    if (urls == null) {
                        name2Urls.put( url, urls = new ArrayList<>());
                    }
                    urls.add( url);
                }
            }
        }
        
        public void prepare() {
            article.spellCheck( text);
            
            if (url == null) {
                synchronized ( Text.class ) {
                    List<String> urls = name2Urls.get(url);
                    if (urls == null) {
                        error( "Undefined target: " + url);
                    } else {
                        for (int i = 1; i < urls.size(); i++) {
                            if (! urls.get(i-1).equals( urls.get(i))) {
                                error( "Ambiguous target: " + text);
                                break;
                            }
                        }
                        url = urls.get(0);
                    }
                }                
            }
            
            if (url != null) {
                if (! Utils.isAbsoluteUrl( url)) {
                    Page page = article.lookupPage( url);
                    if (page == null) {
                        article.error( "This should not appear");
                        url = null;
                    } else {
                        url = Utils.relativePath( article.getSinkFile(), page.getSinkFile());
                    }
                }
            }
        }
    }
    
    class Normal implements Segment {
        private final String text;
        
        Normal( String text) {
            this.text = text.replaceAll( "<", "&lt;").replaceAll( ">", "&gt;");
        }
        
        public void prepare() {
            article.spellCheck( text);
        }
    }
    
    class Raw implements Segment {
        private final String text;
        
        Raw( String text) {
            this.text = text.replaceAll( "&", "&amp;").replaceAll( "<", "&lt;").replaceAll( ">", "&gt;");
        }
        
        public void prepare() {
        }
    }
    
    public Text( Article article, List<String> lines) {
        super( article);
        
        List<Segment> paragraph = new ArrayList<>();
        paragraphs.add(paragraph);
        
        for (String line: lines) {
            lineCount += (line.length() + 1);
            
            if ( line.isBlank() ) {
                paragraphs.add(paragraph = new ArrayList<>());
            } else {
                parse(line, paragraph);
            }
        }
        
        lineCount /= 60;
    }

    public Text( Article article, String line) {
        this( article, Element.toList( line));
    }

    @Override
    public void allowForInset() {
        minLines = 5;
    }

    private String group( int i) {
        return matcher.group(i);
    }
    
    @Override
    public int lineCount() {
        return lineCount;
    }

    private boolean match( Pattern pattern, String text) {
        matcher = pattern.matcher(text);
        return matcher.find();
    }

    private void parse( String text, List<Segment> paragraph) {
        while ( match( nextSpecialChar, text) ) {
            if (! text.isEmpty()) {
                paragraph.add( new Normal( group(1)));
            }
            switch ( group(2).charAt(0) ) {
                case '`':
                    text = parseCode( group(3), paragraph);
                    break;
                case '*':
                    text = parseEmphasized( group(3), paragraph);
                    break;
                default:    
                    text = parseLink( group(3), paragraph);
            }
        }

        paragraph.add( new Normal( text + "\n"));
    }

    private String parseCode( String text, List<Segment> paragraph) {
        if ( match( nextCodeChar, text) ) {
            if ( group(1).isBlank() ) {
                error( "Empty inline code segment");
            }
            paragraph.add( new Raw( group( 1)));
            return group(2);
        } else {
            error( "Bad `` subtext");
            return "";
        }
    }

    private String parseEmphasized(String text, List<Segment> paragraph) {
        if ( match( nextEmphasizedChar, text) ) {
            if ( group(1).isBlank() ) {
                error( "Empty emphasized segment");
            }
            paragraph.add( new Emphasized( group( 1)));
            return group(2);
        } else {
            error( "Bad ** subtext");
            return "";
        }
    }

    private String parseLink(String text, List<Segment> paragraph) {
        if ( match( linkTextEnd, text) ) {
            if ( group(1).isBlank() ) {
                error( "Empty link text");
            }
            if ((! group(2).isEmpty()) && (group(2).charAt(0) == '(')) {
                String label = checkLabel( group( 1));
                if ( match( linkTargetEnd, group(2).substring(1)) ) {
                    paragraph.add( new Linkage( label, group(1)));
                    return group(2);
                } else {
                    error( "Bad [] subtext");
                    return "";
                }
            } else {
                paragraph.add( new Linkage( checkLabel( group( 1)), null));
                return group(2);
            }
        } else {
            error( "Bad [] subtext");
            return "";
        }
    }

    @Override
    public void prepare() {
        for (List<Segment> paragraph: paragraphs) {
            for (Segment segment: paragraph) {
                segment.prepare();
            }
        }
    }
}
