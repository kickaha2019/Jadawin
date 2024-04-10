package com.alofmethbin.jadawin.styles;

import com.alofmethbin.jadawin.Page;
import java.time.LocalDate;

public class DatedEvents extends Events {

    @Override
    public String indexTitle(Page page) {
        LocalDate d = page.getDate();
        if (d != null) {
            return super.indexTitle( page) + 
                   " (" +
                   d.getMonth().toString().substring(0, 3) +
                   " " +
                   d.getYear() +
                   ")"; 
        } else {
            page.error( "Missing date for DatedEvents page");
            return super.indexTitle( page);
        }
    }
}
