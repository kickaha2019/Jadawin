package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Gallery extends Element {
    private List<Text>  labels   = new ArrayList<>();
    private List<Image> images   = new ArrayList<>();
    private static Pattern crack = Pattern.compile( "^(\\S+)\\s+(.+)$");
    
    public Gallery( Article article, List<String> lines) throws IOException {
        super( article);
        
        for (String line: lines) {
            Matcher m = crack.matcher(line);
            if ( m.find() ) {
                Image image = new Image( article, m.group(1));
                Text text = new Text( article, m.group(2));
                if (! (image.hasError() || text.hasError())) {
                    images.add( image);
                    labels.add( text);
                }
            }
        }
        
        if ( images.isEmpty() ) {
            error( "Gallery empty");
        }
    }

    @Override
    public Image getImage() {
        return images.get(0);
    }

    @Override
    public boolean isOverlay() {
        return true;
    }

    @Override
    public int lineCount() {
        return 5 * ((images.size() + 7) / 8);
    }

    @Override
    public void prepare() {
        for (Text label: labels) {
            label.prepare();
        }
    }
}
