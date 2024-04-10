package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Expect extends Element {
    private static int numberOfTests = 0;
    private boolean negate = false;
    private String title, match;
    
    public Expect( Article article, List<String> lines) {
        super( article);
        synchronized ( Expect.class ) {
            numberOfTests ++;
        }

        if (lines.size() != 2) {
            error( "Bad error directive");
        } else {
            title = lines.get(0);
            match = lines.get(1);
        }
    }

    @Override
    public boolean isContent() {
        return false;
    }

    public static int numberOfTests() {
        return numberOfTests;
    }

    @Override
    public String postProcessHTML( String html) {
        Matcher m = Pattern.compile( match, Pattern.MULTILINE).matcher( html);
        if (m.find() ^ negate) {
            error( title);
        }
        return html;
    }
}
