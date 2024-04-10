package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import com.alofmethbin.jadawin.Utils;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.List;

public class Resource extends Element {
    public Resource( Article article, List<String> lines) {
        super( article);
        String relpath = lines.get(0);
        
        File source = article.toSourceFile( relpath);
        File sink   = article.toSinkFile( relpath);
        
        if ( source.exists() ) {
            ByteArrayOutputStream sourceBuffer = new ByteArrayOutputStream();
            Utils.load( source, sourceBuffer);
            
            if ( sink.exists() ) {
                ByteArrayOutputStream sinkBuffer = new ByteArrayOutputStream();
                Utils.load( sink, sinkBuffer);
                
                if (! Utils.compare( sourceBuffer, sinkBuffer)) {
                    Utils.save( sourceBuffer, sink);
                }
            } else {
                Utils.save( sourceBuffer, sink);
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
