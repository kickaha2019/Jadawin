package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Element;
import com.alofmethbin.jadawin.elements.Error;
import com.alofmethbin.jadawin.elements.Expect;
import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.elements.Tag;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.BufferedReader;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.lang.reflect.Constructor;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class Compiler {
    class Config {
        Map<String,int [][]> dimensions;
        String liquid, thymeleaf, root_url, spell_checking, misspelt_words;
        int [] menu_items_per_line;
        int num_menu_styles;
    }
    
    private List<String> errors = new ArrayList<>();
    private File source, sink;
    private Config config;
    private Set<String> words, names, newWords;
    private Set<String> generated;
    private Map<String, List<Page>> key2Pages = new HashMap<>();
    private byte[] fromBuffer = new byte[1000000];
    private byte[] toBuffer = new byte[1000000];
    private LocalDate now   = LocalDate.now();
    private static Pattern assetFilename = Pattern.compile( "\\.(JPG|JPEG|jpg|jpeg|png|zip|gif|svg|webp)$");
    private static Pattern directiveLine = Pattern.compile( "^@(\\S*)(.*)$");
    private static Pattern htmlEntities  = Pattern.compile( "&(.)(acute|caron|cedil|grave|circ|slash|uml|ring);");
    private static Pattern quoteStart    = Pattern.compile( "^(['\"]*)(.*)$");
    private static Pattern quoteEnd      = Pattern.compile( "^(.*)(['\"]*)$");
    private static Pattern prefixStart   = Pattern.compile( "^(pre|quasi|ex|half|mini|multi|non)-(.*)$");

    public Compiler(String source, String configPath, String sink) throws Exception {
        this.source = new File(source);
        this.sink = new File(sink);
        ObjectMapper mapper = new ObjectMapper( new YAMLFactory());
        this.config = mapper.readValue( new File( configPath), Config.class);
        loadWords();
    }

    private void addContent(String verb, Article article, List<String> info, String ref) {
        Class clazz;
        try {
            clazz = Class.forName("com.alofmethbin.jadawin.elements." + Utils.capitalise( verb));
        } catch (ClassNotFoundException cnfe) {
            article.error("Unknown directive: " + verb);
            return;
        }

        Constructor construct;
        try {
            construct = clazz.getConstructor(new Class[]{Article.class, info.getClass()});
        } catch (NoSuchMethodException nsme) {
            article.error("Bad directive: " + verb);
            return;
        };

        Element element;
        try {
            element = (Element) construct.newInstance(new Object[]{article, info});
        } catch (Exception ex) {
            article.error(ex.getMessage());
            return;
        }

        if (!element.hasError()) {
            article.addContent(element, info.size() > 1);
        }
    }
    
    public void compile() {
        out("... Initialised");
        Image.findImages(this.source);
        Article homePage = parseDirectory(null, "");
        out("... Parsed");
        homePage.prepare();
        out("... Prepared");
        regenerate(homePage);
        out("... Generated");
        tidyUp(this.sink);
        out("... Tidied up");
        Tag.checkAllRendered();
        out("... Check tags all used");
        reportNewWords();
        out("... " + (Expect.numberOfTests() + Error.numberOfTests()) + " tests run");
        Error.reportErrors();
        for (String msg : errors) {
            out("*** " + msg);
        }
        if ( hasErrors() ) {
            out("*** " + errors.size() + " errors");
        }
    }

    public void copyResource(String path) throws Exception {
        File from = new File(source, path);
        File to = new File(sink, path);

        if (!to.getParentFile().exists()) {
            to.getParentFile().mkdirs();
        }

        record(to);

        int fromLen = loadBinary(from, fromBuffer);
        if (to.exists()) {
            int toLen = loadBinary(to, toBuffer);
            boolean same = (fromLen == toLen);
            for (int i = 0; same && (i < fromLen); i++) {
                same = (fromBuffer[i] == toBuffer[i]);
            }

            if (same) {
                return;
            }
        }

        try ( FileOutputStream os = new FileOutputStream(to)) {
            os.write(fromBuffer, 0, fromLen);
        } catch (Exception ex) {
            out("*** Error copying resource to " + to);
            throw ex;
        }
    }

    public int [][] dimensions( String key) {
        return config.dimensions.get(key);
    }
    
    public synchronized void error( String path, String msg) {
        errors.add( msg + " [" + path + "]");
    }

    public String getRootURL() {
        return config.root_url;
    }

    private boolean hasErrors() {
        return ! errors.isEmpty();
    }
    
    public boolean isOffsite( String url) {
        if ( url.startsWith( this.config.root_url) ) {
            return false;
        } else if ( Utils.isAbsoluteUrl( url) ) {
            return true;
        } else {
            return false;
        }
    }
    
    private int loadBinary(File from, byte[] fromBuffer) throws Exception {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void loadWords() {
        if (config.spell_checking == null) {return;}
        
        File wordsDir = new File( config.spell_checking);
        if (! (wordsDir.exists() && wordsDir.isDirectory())) {
            errors.add( "Not a directory: spell_checking setting in config");
            return;
        }
        
        this.words    = new HashSet<>();
        this.names    = new HashSet<>();
        this.newWords = new HashSet<>();
        
        for (File f: wordsDir.listFiles()) {
            if ( f.getName().endsWith( ".txt") ) {
                try (BufferedReader reader = new BufferedReader( new FileReader( f))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        String word = line.trim();
                        if ( word.isEmpty() ) {continue;}
                        
                        if ( word.equals( word.toLowerCase()) ) {
                            words.add( word.toLowerCase());
                        } else {
                            names.add( word);
                        }
                    }
                } catch (Exception ex) {
                    errors.add( f.getAbsolutePath() + ": " + ex.getMessage());
                }
            }
        }
    }

    public Page lookupPage( Page referrer, String path, String ref) {
        List<Page> matches = this.key2Pages.get( path);
        if (matches.size() < 1) {
            referrer.error( "Path not found for " + ref);
            return null;
        } else if (matches.size() > 1) {
            referrer.error( "Path not found for " + ref);
            return null;
        } else {
            return matches.get(0);
        }
    }
    
    public int [] menuItemsPerLine() {
        return config.menu_items_per_line;
    }

    public LocalDate now() {
        return now;
    }

    public int numMenuStyles() {
        return config.num_menu_styles;
    }
    
    private void out(String msg) {
        System.out.println(msg);
    }

    private Article parseDirectory( Article parent, String dir) {
        File dirFile = dir.equals("") ? sink : new File( sink, dir);
        if (! dirFile.exists()) {dirFile.mkdirs();}
        
        Article dirArticle = new Article( this, parent, dir + "/index.txt");
        remember( dir.isEmpty() ? "." : dir, dirArticle);
        
        if (parent != null) {
            parent.addChild( dirArticle);
        }
        
        for (File f: (new File( source, dir)).listFiles()) {
            if ( f.getName().startsWith( ".") ) {continue;}
            if ( f.getName().startsWith( "_") ) {continue;}
            String path = dir + "/" + f.getName();
            
            if ( f.isDirectory() ) {
                parseDirectory( dirArticle, path);
            } else if ( f.getName().equals( "index.txt") ) {
                parseFile( dirArticle, f);
            } else if ( f.getName().endsWith( ".txt") ) {
                Article a = new Article( this, dirArticle, path);
                dirArticle.addChild( a);
                remember( path, a);
                parseFile( a, f);
            } else if ( assetFilename.matcher( f.getName()).matches() ) {
                //remember( path, new File( sink, path));
            } else {
                dirArticle.error( "Unhandled file: " + f.getName());
            }
        }
        
        dirArticle.discardFutureChildren();
        return dirArticle;
    }

    private void parseFile( Article article, File f) {
        try (BufferedReader reader = new BufferedReader( new FileReader( f))) {
            List<String> lines = new ArrayList<>();
            String line, line1;
            while ((line = reader.readLine()) != null) {
               Matcher m = directiveLine.matcher( line);
               if ( m.matches() ) {
                   lines.clear();
                   if (! m.group(2).isBlank()) {
                       lines.add( m.group(2).trim());
                       addContent( m.group(1), article, lines, line);
                   } else {
                       reader.mark( 1000);
                       int lastNonWhite = 0;
                       while ((line1 = reader.readLine()) != null) {
                           if ( directiveLine.matcher( line1).find() ) {
                               reader.reset();
                               break;
                           } else {
                               reader.mark( 1000);
                               lines.add( line1);
                               if ( line1.isBlank() ) {
                                   lastNonWhite = lines.size();
                               }
                           }
                           
                           addContent( m.group(1), article, lines.subList( 0, lastNonWhite), line);
                       }
                   }
               } else if (! line.isBlank()) {
                   article.error( "Expected directive: " + line);
                   break;
               }
            }
        } catch (Exception ex) {
            article.error( ex.getMessage());
        }
    }

    public void record( File to) {
        this.generated.add( to.getAbsolutePath());
    }

    private void regenerate(Article homePage) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void remember( String path, Page page) {
        remember1( path, page);
        for (int i = 1; i < path.length() - 1; i++) {
            if ( path.substring(i, i+1).equals( "/") ) {
                remember1( path.substring(i), page);
            }
        }
    }

    private void remember1( String path, Page page) {
        if (! key2Pages.containsKey( path)) {
            List<Page> list = new ArrayList<>();
            key2Pages.put( path, list);
            list.add( page);
        } else {
            key2Pages.get( path).add( page);
        }
    }

    private void reportNewWords() {
        if (config.misspelt_words != null) {
            try (FileWriter w = new FileWriter( config.misspelt_words)) {
               for (String word: newWords) {
                   w.write( word + "\n");
               }
            } catch (Exception ex) {
               System.err.println( "Error writing unknown words: " + ex.getMessage());
            }
        }
    }

    public File sourceFile( String path) {
        return new File( source, path);
    }

    public void spellCheck( Article article, String text) {
        if (this.words == null) {return;}
        
        for (String part: text.split( "[,\\.!\\? \\n\\(\\);:]")) {
            String word = part;
            
            Matcher m = Compiler.quoteStart.matcher( word);
            if ( m.find() ) {
                word = m.group(2);
            }
            
            m = Compiler.prefixStart.matcher( word);
            if ( m.find() ) {
                word = m.group(2);
            }
            
            m = Compiler.quoteEnd.matcher( word);
            if ( m.find() ) {
                word = m.group(1);
            }
            
            m = Compiler.htmlEntities.matcher( word);
            while ( m.find() ) {
                word = word.substring( 0, m.start()) + 
                       m.group(1) + 
                       word.substring( m.end(), word.length());
                m    = Compiler.htmlEntities.matcher( word);
            }
            
            if ( this.words.contains( word.toLowerCase()) ) {continue;}
            if ( this.names.contains( word) ) {continue;}
            
            this.newWords.add( word);
            article.error( "Unknown word: " + part);
        }
    }
    
    private boolean tidyUp( File dir) {
        boolean keep = false;
        for (File child: dir.listFiles()) {
            if ( child.isDirectory() ) {
                if ( tidyUp( child) ) {
                    keep = true;
                } else {
                    out( "Deleting " + toPath(child));
                    child.delete();
                }
            } else if ( child.getName().startsWith( ".") ) {
                child.delete();
            } else if ( this.generated.contains( child.getAbsolutePath()) ) {
                keep = true;
            } else {
                out( "Deleting " + toPath(child));
                child.delete();
            }
        }
        return keep;
    }

    public File toSinkFile( String path) {
        return new File( sink, path);
    }

    public File toSourceFile( String path) {
        return new File( source, path);
    }

    public String toPath( File file) {
        return Utils.toPath( sink, file);
    }

    public static void main(String[] args) {
        try {
            Compiler c = new Compiler( args[0], args[1], args[2]);
            c.compile();
            if ( c.hasErrors() ) {
                System.exit(1);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }
    }
}
