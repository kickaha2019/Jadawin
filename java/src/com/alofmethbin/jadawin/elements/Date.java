package com.alofmethbin.jadawin.elements;

import com.alofmethbin.jadawin.Article;
import java.time.LocalDate;
import java.util.List;
import java.util.regex.Pattern;

public class Date extends Element {
    private boolean first;
    private LocalDate date;
    private static String [] months = new String [] 
       {"jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"};
    private static Pattern numericStart = Pattern.compile( "^(\\d+)");
       
    public Date( Article article, List<String> lines) {
        super( article);
        first = (article.getDate() == null);
        date  = textToDate( lines.get(0));
    }
    
    public LocalDate getDate() {
        return date;
    }

    @Override
    public boolean isContent() {
        return ! first;
    }

    @Override
    public boolean isMultiline() {
        return false;
    }

    @Override
    public boolean isSpecial() {
        return first;
    }

    private LocalDate textToDate( String text) {
      int day   = -1;
      int month = -1;
      int year  = -1;

      for (String part: text.split( " ")) {
        if ( match( numericStart, part) ) {
            int i = Integer.parseInt( group(1));
            if (i >= 1800) {
                year = i;
            } else if ((i > 0) && (i < 32)) {
                day = i;
            }
        } else if (part.length() >= 3) {
            for (int j = 0; j < months.length; j++) {
                if ( months[j].equalsIgnoreCase( part.substring(0,3))) {
                    month = j + 1;
                    break;
                }
            }
        }
      }
      
      if ((day > 0) && (month > 0) && (year > 0)) {
          return LocalDate.of(year, month, day);
      } else {
          error( "Bad date [" + text + "]");
          return null;
      }
    }
}
