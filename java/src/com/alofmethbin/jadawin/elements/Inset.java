package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.io.IOException;
import java.util.List;

public class Inset extends Image {
    public Inset( Article article, List<String> lines) throws IOException {
        super( article, lines);
    }

    @Override
    public boolean isContent() {
        return false;
    }

    @Override
    public boolean isInset() {
        return true;
    }

    @Override
    public boolean isOverlay() {
        return true;
    }
}
