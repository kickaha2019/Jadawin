package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Any;
import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Utils;
import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifSubIFDDirectory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.imageio.ImageIO;

public class Image extends Element {
    private static Map<String,String> advices  = new HashMap<>();
    private static Pattern validAdvices        = Pattern.compile( "^(top|bottom|left|right)$");
    private static Pattern validExtensions     = Pattern.compile( "\\.(png|jpg|jpeg|gif|webp)$", Pattern.CASE_INSENSITIVE);
    private static Map<String,ImageInfo> infos = new HashMap<>();
    private ImageInfo info;
    
    static class ImageInfo {
        private int orient;
        String path;
        int width, height;
        long timestamp;
        private boolean found;
        
        ImageInfo( Any any) {
            this.path = any.get("path").asString();
            found     = false;
            orient    = any.get( "orient").asInt();
            width     = any.get( "width").asInt();
            height    = any.get( "height").asInt();
            timestamp = any.get( "timestamp").asLong();
        }
        
        ImageInfo( String path) {
            this.path = path;
            found     = true;
            width     = -1;
        }

        private void save( FileWriter writer) throws IOException {
            writer.write( "- path: \"" + path + "\"\n");
            writer.write( "  timestamp: " + timestamp + "\n");
            writer.write( "  height: " + height + "\n");
            writer.write( "  width: " + width + "\n");
            writer.write( "  orient: " + orient + "\n");
        }
    }
    
    public Image( Article article, List<String> lines) throws IOException {
        this( article, lines.isEmpty() ? null : lines.get( 0));
    }
    
    public Image( Article article, String defn) throws IOException {
        super( article);
        if (defn == null) {
            error( typeName() + " missing image name");
            return;
        }
        
        String advice=null, source=defn;
        String [] parts = source.split( ";", 2);
        if (parts.length > 1) {
            source = parts[0];
            advice = parts[1];
            
            Matcher m = validAdvices.matcher(advice);
            if (! m.find()) {
                error( "Unsupported image annotation: " + advice);
                return;
            }
        }
        
        Matcher m = validExtensions.matcher( source);
        if (! m.find()) {
            error( "Not an image file: " + source);
            return;
        }
        
        String path = article.toPath( article.toSinkFile( source));
        info = infos.get( path);
        if (info == null) {
            error( "File not found: " + defn);
            return;
        }
           
        if (info.width < 1) {
            error( "Badly formatted image file: " + defn);
            return;
        }
        
        synchronized ( Image.class ) {
            if (advice != null) {
                if (advices.get( info.path) != null) {
                    if (! advice.equals( advices.get( info.path))) {
                        error( "Inconsistent advice for image: " + source);
                    }
                } else {
                    advices.put( info.path, advice);
                }
            }
        }
    }

    private static int [] constrainDims( int [] target, int [] actual) {
        if (actual[0] * target[1] >= actual[1] * target[0]) {
            if (actual[0] > target[0]) {
                return new int [] {target[0], (actual[1] * target[0]) / actual[0]};
            }
        } else {
            if (actual[1] > target[1]) {
                return new int [] {(actual[0] * target[1]) / actual[1], target[1]};
            }
        }
        
        return actual;
    }
    
    public static void findImages( File source) throws IOException {
        File meta = new File( source, "_images1.yaml");
        ObjectMapper mapper = new ObjectMapper( new YAMLFactory());
        
        if ( meta.exists() ) {
            try {
                Any old = new Any( mapper.readValue( meta, List.class));
            
                for (int i = 0; i < old.size(); i++) {
                    ImageInfo info = new ImageInfo( old.get(i));
                    infos.put( info.path, info);
                    info.found = false;
                }
            } catch (Exception ex) {
                warn( "Unable to load _images.yaml: " + ex.getMessage());
            }
        }
        
        findImages1( source, source);
        
        try (FileWriter writer = new FileWriter( meta)) {
            writer.write( "---\n");
            for (ImageInfo info: infos.values()) {
                if ( info.found ) {
                    info.save( writer);
                }
            }
        } catch (Exception ex) {
            System.err.println( "*** Unable to save _images.yaml: " + ex.getMessage());
            System.exit(1);
        }
    }
        
    public static void findImages1( File source, File dir) throws IOException {
        for (File f: dir.listFiles()) {
            if ( f.isDirectory() ) {
                findImages1( source, f);
            } else {
                Matcher m = validExtensions.matcher( f.getName());
                if ( m.find() ) {
                    String path = Utils.toPath( source, f);
                    ImageInfo info = infos.get( path);
                    if (info != null) {
                        info.found = true;
                    } else {
                        infos.put( path, info = new ImageInfo( path));
                    }
                    
                    long ts = f.lastModified();
                    if (ts != info.timestamp) {
                        info.timestamp = ts;
                        getImageDetails( f, info);
                    }
                }
            }
        }
    }
    
    public String getAnchor() {
        return "I" + getIndex();
    }
    
    public int getHeight() {return info.height;}

    private static void getImageDetails( File file, ImageInfo info) {
        try {
            Metadata meta = ImageMetadataReader.readMetadata(file);
            ExifSubIFDDirectory exif = meta.getFirstDirectoryOfType(ExifSubIFDDirectory.class);
            if (exif != null) {
                    info.orient = exif.getInt( ExifSubIFDDirectory.TAG_ORIENTATION);
            }
        } catch (Exception ex) {
            info.orient = 0;
        }
        
        try {
            BufferedImage bi = ImageIO.read( file);
            if (info.orient < 4) {
                info.width  = bi.getWidth();
                info.height = bi.getHeight();
            } else {
                info.width  = bi.getHeight();
                info.height = bi.getWidth();
            }
        } catch (Exception ex) {
            info.width = -1;
        }
    }

    public static List<int []> getScaledDims( List<int []> dims, List<Image> images) {
        float aspect = 1000;
        for (Image i: images) {
            if ( i.hasError() ) {continue;}
            float a = (1.0f * i.getHeight()) / i.getWidth();
            if (a < aspect) {aspect = a;}
        }
        
        int [] largest = dims.get( dims.size() - 1);
        float a = (1.0f * largest[1]) / largest[0];
        if (a < aspect) {aspect = a;}
        
        List<int []> scaled = new ArrayList<>();
        for (int [] dim: dims) {
            if ((dim[0] * aspect) > dim[1]) {
                scaled.add( new int [] {(int) (dim[1] / aspect), dim[1]});
            } else {
                scaled.add( new int [] {dim[0], (int) (dim[0] * aspect)});
            }
        }
        return scaled;
    }

    @Override
    public Image getImage() {
        return this;
    }

    public int getWidth() {
        return info.width;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }
}
