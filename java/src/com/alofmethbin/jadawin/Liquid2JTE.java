package com.alofmethbin.jadawin;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Liquid2JTE {
    private static Map<String, Pattern> patterns = new HashMap<>();
    private static Matcher patternMatcher;
    private static String VARIABLE_PATTERN = "[a-zA-Z0-9\\.\\[\\]_]*";
    private int errors = 0;

    private class Function {
        String name;
        List<Token> tokens;
        List<String> params = new ArrayList<>();
        List<String> loops  = new ArrayList<>();

        Function(String name, List<Token> tokens) {
            this.name = name;
            this.tokens = tokens;
        }

        private void addLoop( String name) {
            if (! loops.contains(name)) {
                loops.add( name);
            }
        }

        void addParam( String name) {
            name = name.split( "[\\.\\[]")[0];
            if ( name.isBlank() ) {
                error( "adding blank parameter");
            }
            if (! params.contains(name)) {
                params.add( name);
            }
        }

        private void addParamsFromChain(String text) {
            String [] chain = text.split( "\\|");
            addParamsFromExpression( chain[0]);
            for (int i = 1; i < chain.length; i++) {
                if ( match( "^(.*):(.*)$", chain[i]) ) {
                    addParamsFromExpression( group(2));
                } else if (! chain[i].trim().equals( "floor")) {
                    error( "Unable to parse " + text);
                }
            }
        }

        private void addParamsFromExpression(String text) {
            for (String element: parseExpression( text)) {
                if ( variable( element) ) {
                    addParam( element);
                }
            }
        }

        private void deduceParams() {
            for (Token t: tokens) {
                t.deduceParams( this);
            }
        }
        
        void dump() {
            System.out.print(name);
            System.out.println( "(");
            String separ = " ";
            for (String param: params) {
                if (! loops.contains( param)) {
                    System.out.print( separ);
                    separ = ", ";
                    System.out.print( param);
                }
            }
            System.out.println( ")");
            for (Token token : tokens) {
                System.out.print("  ");
                token.dump();
            }
            System.out.println();
        }
        
        void error( String msg) {
            Liquid2JTE.this.error( name, msg);
        }

        private List<String> parseExpression( String text) {
            List<String> parsed = new ArrayList<>();
            for (String e: text.split( " ")) {
                while (! e.isBlank()) {
                    if ( match( "^\\s*(\\(|\\)|\\+|\\-|!=|==|>|<|" + VARIABLE_PATTERN + ")(.*)$", e) ) {
                        parsed.add( group(1));
                        e = group(2);
                    } else {
                        error( "Unable to parse " + text);
                    }
                }
            }
            return parsed;
        }

        private boolean variable( String element) {
            return ! match( "^(\\(|\\)|\\+|\\-|==|>|<|!=|and|or)$", element);
        }
    }

    private static class Token {
        Type type;
        String text;

        public Token(Type type, String text) {
            this.type = type;
            this.text = text;
        }

        private void deduceParams( Function function) {
            switch ( type ) {
                case BREAK:
                    break;
                case CASE:
                    function.addParam( text.trim());
                    break;
                case ELSE:
                    break;
                case EMBED:
                    function.addParamsFromChain( text);
                    break;
                case ENDCASE:
                case ENDFOR:
                case ENDIF:
                case ENDUNLESS:
                    break;
                case FOR:
                    if ( match( "^([a-zA-Z]*) in\\s+(" + VARIABLE_PATTERN + ")$", text) ) {
                        function.addLoop( group(1));
                        function.addParam( group(2));
                    } else if ( match( "^([a-zA-Z]*) in\\s*(\\(\\d+\\.\\.\\d+\\))$", text) ) {
                        function.addLoop( group(1));
                    } else {
                        function.error( "Unable to parse for expression");
                    }
                    break;
                case IF:
                    function.addParamsFromChain( text);
                    break;
                case INCLUDE:
                    if ( match( "^\\s*'[a-z_]*'\\s*(with|,)\\s*(.*)$", text) ) {
                        for (String p: group(1).split( ",")) {
                            if ( match( "^(.*):(.*)$", p) ) {
                                function.addParam( group(2));
                            } else {
                                function.error( "Unable to parse include expression");
                            }
                        }
                    } else {
                        function.error( "Unable to parse include expression");
                    }
                    break;
                case TEXT:
                    break;
                case UNLESS:
                    function.addParamsFromChain( text);
                    break;
                case WHEN:
                    break;
                default:  
                    function.error( "deduceParams unhandled type " + type.name());
            }
        }

        private void dump() {
            System.out.println(type.name() + ": "
                    + ((text.length() > 30) ? text.substring(0, 30) : text).replace("\n", " "));
        }
    }

    enum Type {
        TEXT, EMBED, IF, INCLUDE, FOR, 
        ENDFOR, ELSE, ENDIF, CASE, WHEN, 
        ENDCASE, BREAK, UNLESS, ENDUNLESS
    }

    private final String sourcePath;
    private final String sinkPath;
    private final Map<String, Function> functions = new HashMap<>();

    public Liquid2JTE( String source, String sink) {
        this.sourcePath = source;
        this.sinkPath = sink;
    }

    public static void main(String[] args) {
        try {
            Liquid2JTE l2j = new Liquid2JTE(args[0], args[1]);
            l2j.loadSources();
            l2j.deduceParams();
            if (l2j.errors > 0) {
                System.exit(1);
            }
            l2j.report();
        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }
    }

    private void deduceParams() {
        for (Function f: functions.values()) {
            f.deduceParams();
        }
    }

    private void error(String name, String msg) {
        errors++;
        System.err.println("*** " + msg + " in [" + name + "]");
    }

    private static String group( int index) {
        return patternMatcher.group( index);
    }
    
    private void loadSources() throws Exception {
        for (File f : (new File(sourcePath)).listFiles()) {
            if (f.getName().endsWith(".liquid")) {
                StringBuilder b = new StringBuilder();
                try (BufferedReader br = new BufferedReader(new FileReader(f))) {
                    String line;
                    while ((line = br.readLine()) != null) {
                        if (!b.isEmpty()) {
                            b.append("\n");
                        }
                        b.append(line);
                    }
                }

                String name = f.getName().split("\\.")[0];
                functions.put(name, new Function(name, tokenise(name, b.toString())));
            }
        }
    }

    private static boolean match(String regex, String text) {
        patternMatcher = matcher( regex, text);
        return patternMatcher.find();
    }

    private static Matcher matcher(String regex, String text) {
        if (!patterns.containsKey(regex)) {
            patterns.put(regex, Pattern.compile(regex, Pattern.MULTILINE));
        }
        return patterns.get(regex).matcher(text);
    }

    private void report() {
        for (Function f : functions.values()) {
            f.dump();
        }
    }

    private List<Token> tokenise(String name, String text) {
        int from = 0;
        Matcher start = matcher("(\\{\\{|\\{%(-|))", text);
        Matcher endEmbed = matcher("\\}\\}", text);
        Matcher endDir = matcher("(-|)%\\}", text);
        List<Token> tokens = new ArrayList<>();

        while (start.find(from)) {
            tokens.add(new Token(Type.TEXT,
                    text.substring(from, start.start())));
            if (start.group(0).startsWith("{{")) {
                if (endEmbed.find(start.end())) {
                    tokens.add(new Token(Type.EMBED,
                            text.substring(start.start() + 2,
                                    endEmbed.start())));
                    from = endEmbed.end();
                } else {
                    error(name, "End of {{ not found");
                    break;
                }
            } else if (endDir.find(start.end())) {
                
                String directive = text.substring(start.end(),
                                                  endDir.start());
                Matcher m = matcher("^\\s*([\\w]*)", directive);
                if (m.find()) {
                    String data = directive.substring(m.end()).trim();
                    Type type = null;
                    switch (m.group(1)) {
                        case "break":
                            type = Type.BREAK;
                            break;
                        case "case":
                            type = Type.CASE;
                            break;
                        case "else":
                            type = Type.ELSE;
                            break;
                        case "endcase":
                            type = Type.ENDCASE;
                            break;
                        case "endif":
                            type = Type.ENDIF;
                            break;
                        case "endfor":
                            type = Type.ENDFOR;
                            break;
                        case "endunless":
                            type = Type.ENDUNLESS;
                            break;
                        case "for":
                            type = Type.FOR;
                            break;
                        case "if":
                            type = Type.IF;
                            break;
                        case "include":
                            type = Type.INCLUDE;
                            break;
                        case "unless":
                            type = Type.UNLESS;
                            break;
                        case "when":
                            type = Type.WHEN;
                            break;
                        default:
                            //System.err.println( directive);
                            error(name, "Unhandled directive: " + m.group(1));
                    }
                    if (type != null) {
                        tokens.add(new Token(type, data));
                    }
                } else {
                    error(name, "No directive after {%");
                }
                from = endDir.end();
            } else {
                error(name, "End of {% not found");
                System.err.println(text.substring(start.start()));
                break;
            }
        }

        tokens.add(new Token(Type.TEXT, text.substring(from)));
        return tokens;
    }
}
