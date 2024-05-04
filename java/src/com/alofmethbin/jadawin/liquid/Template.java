package com.alofmethbin.jadawin.liquid;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Template {
    private List<Stanza> stanzas = new ArrayList<>();
    private final String name;
    private Map<String, Pattern> patterns = new HashMap<>();
    private Matcher patternMatcher;
    
    private Template( String name, List<Stanza> stanzas) {
        this.name    = name;
        this.stanzas = stanzas;
    }

    private String group( int index) {
        return patternMatcher.group( index);
    }

    private boolean match(String regex, String text) {
        patternMatcher = matcher( regex, text);
        return patternMatcher.find();
    }

    private Matcher matcher(String regex, String text) {
        if (!patterns.containsKey(regex)) {
            patterns.put(regex, Pattern.compile(regex, Pattern.MULTILINE));
        }
        return patterns.get(regex).matcher(text);
    }
    
    public static Template parse( Monitor monitor, String name, File file) {
        return null;
    }
    
    private String read( File file) throws Exception {
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

        return b.toString();
    }

    private List<Stanza> extractStanzas( Monitor monitor, String name, String text) {
        int from = 0;
        Matcher start = matcher("(\\{\\{|\\{%(-|))", text);
        Matcher endEmbed = matcher("\\}\\}", text);
        Matcher endDir = matcher("(-|)%\\}", text);
        List<Stanza> stanzas = new ArrayList<>();

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
