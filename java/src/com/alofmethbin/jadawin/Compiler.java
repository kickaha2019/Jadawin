package com.alofmethbin.jadawin;

import com.alofmethbin.jadawin.elements.Element;
import com.alofmethbin.jadawin.elements.Error;
import com.alofmethbin.jadawin.elements.Expect;
import com.alofmethbin.jadawin.elements.Image;
import com.alofmethbin.jadawin.elements.Tag;
import java.io.BufferedReader;
import org.yaml.snakeyaml.Yaml;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class Compiler {
    private List<String> errors = new ArrayList<>();
    private File source, sink;
    private Map<String, Object> config;
    private Set<String> words, names, newWords;
    private Set<String> generated;
    private Map<String, List<String>> key2Paths = new HashMap<>();
    private byte[] fromBuffer = new byte[1000000];
    private byte[] toBuffer = new byte[1000000];
    private static Pattern assetFilename = Pattern.compile( "\\.(JPG|JPEG|jpg|jpeg|png|zip|gif|svg|webp)$");
    private static Pattern directiveLine = Pattern.compile( "^@(\\S*)(.*)$");

    public Compiler(String source, String config, String sink) throws Exception {
        this.source = new File(source);
        this.sink = new File(sink);
        Yaml yaml = new Yaml();
        this.config = yaml.load(new FileInputStream(config));
        loadWords();
    }

    private void addContent(String verb, Article article, List<String> info, String ref) {
        String verbC = verb.substring(0, 1).toUpperCase() + verb.substring(1);

        Class clazz;
        try {
            clazz = Class.forName("com.alofmethbin.jadawin.elements." + verbC);
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
        prepare(homePage);
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
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
    
    public synchronized void error( String path, String msg) {
        errors.add( msg + " [" + path + "]");
    }

    private boolean hasErrors() {
        return ! errors.isEmpty();
    }
    
    private int loadBinary(File from, byte[] fromBuffer) throws Exception {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void loadWords() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void out(String msg) {
        System.out.println(msg);
    }

    private Article parseDirectory( Article parent, String dir) {
        File dirFile = new File( sink, dir);
        if (! dirFile.exists()) {dirFile.mkdirs();}
        
        File file = new File( dirFile, "index.html");
        Article dirArticle = new Article( this, parent, file);
        remember(dir.equals( "") ? "." : dir, file);
        
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
                Article a = new Article( this, 
                                         dirArticle, 
                                         new File( dirFile, f.getName().replace( ".txt", ".html")));
                dirArticle.addChild( a);
                parseFile( a, f);
            } else if ( assetFilename.matcher( f.getName()).matches() ) {
                remember( path, new File( sink, path));
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
                   if (! m.group(2).trim().equals( "")) {
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
                               if ( line1.trim().equals( "") ) {
                                   lastNonWhite = lines.size();
                               }
                           }
                           
                           addContent( m.group(1), article, lines.subList( 0, lastNonWhite), line);
                       }
                   }
               } else if (! line.trim().equals( "")) {
                   article.error( "Expected directive: " + line);
                   break;
               }
            }
        } catch (Exception ex) {
            article.error( ex.getMessage());
        }
    }

    private void prepare(Article homePage) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public String prettify(String text) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void record(File to) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void regenerate(Article homePage) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public String relativePath(File from, File to) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void remember( String path, File file) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
    
    private void reportErrors() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void reportNewWords() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    private void tidyUp(File sink) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public String toPath( File file) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    public static void main(String[] args) {

    }
}
