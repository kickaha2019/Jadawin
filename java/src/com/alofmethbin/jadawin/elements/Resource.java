package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Utils;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.List;

public class Resource extends Element {
    public Resource( Article article, List<String> lines) throws Exception {
        super( article);
        String relpath = lines.get(0);
        
        File source = article.toSourceFile( relpath);
        File sink   = article.toSinkFile( relpath);
        
        if ( source.exists() ) {
            byte [] neu = Utils.load( source);
            
            if ( sink.exists() ) {
                byte [] old = Utils.load( sink);
                
                if (! Utils.compare( neu, old)) {
                    Utils.save( neu, sink);
                }
            } else {
                Utils.save( neu, sink);
            }
        } else {
            error( "Unknown resource: " + relpath);
        }
        
        article.record( sink);
    }

    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }
}
