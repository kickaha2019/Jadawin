package com.alofmethbin.jadawin;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Any {
    private Object object;
    
    public Any( Object o) {
        object = o;
    }
    
    public int asInt() {
        return (Integer) object;
    }
    
    public int [] asInts() {
        int [] values = new int [size()];
        for (int i = 0; i < values.length; i++) {
            values[i] = get(i).asInt();
        }
        return values;
    }
    
    public int [][] asInts2() {
        int [][] values = new int [size()][];
        for (int i = 0; i < values.length; i++) {
            values[i] = get(i).asInts();
        }
        return values;
    }
    
    public Map<String,int [][]> asInts2Map() {
        Map<String,int [][]> map = new HashMap<>();
        for (Object key: ((Map) object).keySet()) {
            map.put( (String) key, get( (String) key).asInts2());
        }
        return map;
    }
    
    public long asLong() {
        if (object instanceof Integer) {return (Integer) object;}
        return (Long) object;
    }
    
    public String asString() {
        return (String) object;
    }
    
    public Map<String,String> asStringMap() {
        Map<String,String> map = new HashMap<>();
        for (Object key: ((Map) object).keySet()) {
            map.put( (String) key, get( (String) key).asString());
        }
        return map;
    }
    
    public Any get( int index) {
        return new Any( ((List) object).get( index));
    }
    
    public Any get( String name) {
        return new Any( ((Map) object).get( name));
    }
    
    public int size() {
        return ((List) object).size();
    }
}
