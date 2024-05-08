class Transpiler
  RESERVED_WORDS = ['or', 'and', 'true', 'false']

  class Context
    def initialize( sink, clazz)
      @io     = File.open( sink + '/' + clazz + '.rb', 'w')
      @io.puts <<"HEAD"
class #{clazz}
  def self.x( context, *args)
    args.each do |arg|
      if context.is_a?( Hash)
        context = context[arg]
      else
        context = context.send( arg.to_sym)
      end
    end
    context
  end
HEAD
      @indent = 0
      @rstrip = false
    end

    def close
      @io.puts "end"
      @io.close
    end

    def indent( delta)
      @indent += delta
    end

    def indented
      @indent
    end

    def rstrip( flag=true)
      @rstrip = true
    end

    def print( text)
      @io.print( (' ' * @indent) + text)
    end

    def puts( text)
      print( text + "\n")
    end

    def wrap_text( text, check=true)
      if @rstrip
        @rstrip = false
        text = text.lstrip
        return if text == ''
      end

      if check && (/#\{/ =~ text)
        raise 'Illegal character sequence #{'
      end

      puts "h << \"#{text.gsub("\n","\\\\n").gsub('"',"\\\"")}\""
    end
  end

  def initialize
    @error_location = nil
  end

  def handle_break( tokens, context)
    context.puts( 'break')
  end

  def handle_case( tokens, context)
    context.puts( 'case ' + handle_expression(tokens))
    context.indent( 4)
    context.rstrip
  end

  def handle_else( tokens, context)
    context.indent( -2)
    context.puts( 'else')
    context.indent( 2)
  end

  def handle_endcase( tokens, context)
    context.indent( -4)
    context.puts( 'end')
  end

  def handle_endif( tokens, context)
    context.indent( -2)
    context.puts( 'end')
  end

  def handle_endfor( tokens, context)
    context.indent( -2)
    context.puts( 'end')
    context.puts "c[name#{context.indented}] = value#{context.indented}"
  end

  def handle_endunless( tokens, context)
    context.indent( -2)
    context.puts( 'end')
  end

  def handle_expression(tokens)
    [].tap do |handled|
      i, inside_reference, inside_filter = 0, false, false
      while i < tokens.size
        token = tokens[i]
        i += 1

        if (/^[a-z]/i =~ token) &&
            (! RESERVED_WORDS.include?( token))
          unless inside_reference
            inside_reference = true
            handled << 'x(c,'
          end
          handled << "\"#{token}\""
        elsif token == ':'
        elsif token == '.'
          handled << ','
        else
          if inside_reference
            handled << ')'
            inside_reference = false
          end
          if token == '|'
            if inside_filter
              handled << ')'
            end
            inside_filter = true
            handled.unshift( "f_#{tokens[i+1]}(")
            i += 1
          else
            handled << token
          end
        end
      end

      if inside_reference
        handled << ')'
      end

      if inside_filter
        handled << ')'
      end
    end.join('')
  end

  def handle_for( tokens, context)
    context.puts "name#{context.indented}  = '#{tokens[0]}'"
    context.puts "value#{context.indented} = c['#{tokens[0]}']"
    if tokens[1] != 'in'
      raise 'Unhandled for directive'
    end
    context.puts handle_expression(tokens[2..-1]) + '.each do |loop|'
    context.indent( 2)
    context.puts "c['#{tokens[0]}'] = loop"
  end

  def handle_if( tokens, context)
    context.puts( 'if ' + handle_expression(tokens))
    context.indent( 2)
  end

  def handle_include( tokens, context)
    context.puts( 'c1 = Hash.new {|h,k| h[k] = c[k]}')

    from = 1
    from += 1 if tokens[from] == ','
    from += 1 if tokens[from] == 'with'

    while (from < tokens.size)
      raise 'Bad syntax in include directive' if tokens[from+1] != ':'
      i = from+2
      while (i < tokens.size) && (tokens[i] != ',')
        i += 1
      end
      context.puts( "c1[#{tokens[from]}] = " +
                    handle_expression(tokens[from+2...i]))
      from = i+1
    end

    context.puts( "h << #{tokens[0][1..-2]}( c1)")
  end

  def handle_text( text, context)
    from = 0
    while ! (i = text.index( '{{', from)).nil?
      context.wrap_text( text[from...i]) if from < i
      tokens, j = tokenise( text, i+2, '}}')
      context.puts( 'h << "#{' + handle_expression(tokens) + '}"')
      from = j
    end
    context.wrap_text( text[from..-1]) if from < text.size
  end

  def handle_unless( tokens, context)
    context.puts( 'unless ' + handle_expression(tokens))
    context.indent( 2)
  end

  def handle_when( tokens, context)
    context.indent( -2)
    context.puts( 'when ' + handle_expression(tokens))
    context.indent( 2)
  end

  def stanzas( text)
    from = 0
    begin
      while ! (i = text.index( '{%', from)).nil?
        if i > from
          yield text[from...i]
        end

        from = i+2
        tokens, j = tokenise( text, from, '%}')
        if tokens
          yield tokens
          from = j
        else
          raise "Missing %}"
        end
      end
      yield text[from..-1] if from < text.size
    rescue Exception => bang
      @error_location = text[from..(from+29)].gsub("\n",' ')
      raise bang
    end
  end

  def suppress_whitespace( stanza)
    return stanza if stanza.empty?

    if stanza[0] == '-'
      stanza = stanza[1..-1]
    elsif /^\-/ =~ stanza[0]
      stanza[0] = stanza[0][1..-1]
    end

    return stanza if stanza.empty?

    if stanza[-1] == '-'
      return stanza[0..-2]
    elsif /^\-/ =~ stanza[-1]
      stanza[-1] = stanza[-1][1..-1]
    end

    stanza
  end

  def template( name, text, context)
    begin
      context.indent(2)
      context.puts "def self.#{name}(c)"
      context.indent(2)
      context.puts 'h = []'

      stanzas( text) do |stanza|
        if stanza.is_a?( Array)
          stanza = suppress_whitespace( stanza)
          unless stanza.empty?
            self.send( ('handle_' + stanza[0]).to_sym,

                       stanza[1..-1], context)
          end
        else
          handle_text( stanza, context)
        end
      end

      context.puts "h.join('')"
      context.indent(-2)
      context.puts 'end'
    rescue Exception => bang
      puts "*** File:  #{name}"
      puts "*** Text:  #{@error_location}" if @error_location
      puts "*** Error: #{bang.message}"
    end
  end

  def tokenise( text, from, stop)
    tokens = []
    while ! (i = text.index( /\S/, from)).nil?
      if ('"' == text[i..i]) || ("'" == text[i..i])
        if j = text.index( text[i..i], i+1)
          tokens << text[i..j]
          from = j+1
        else
          raise "Unclosed quoted string"
        end
      elsif /[a-z0-9_]/i =~ text[i..i]
        if j = text.index( /[^a-z0-9_]/i, i+1)
          tokens << text[i...j]
          from = j
        else
          raise "Missing #{stop}"
        end
      else
        if j = text.index( /["'a-z0-9_\s]/i, i+1)
          token = text[i...j]
          if (! (k = text.index( stop, i)).nil?) && (k < j)
            tokens << text[i...k] if k > i
            return tokens, (k+stop.size)
          end
          tokens << token
          from = j
        else
          if ! (k = text.index( stop, i)).nil?
            tokens << text[i...k] if k > i
            return tokens, (k+stop.size)
          end
          raise "Missing #{stop}"
        end
      end
    end
  end

  def transpile_dir( source, clazz, sink)
    context = Context.new( sink, clazz)
    Dir.entries( source).each do |f|
      if m = /^(.*)\.liquid$/.match( f)
        template( m[1], IO.read( source + '/' + f), context)
      end
    end
    context.close
  end

  def transpile_source( name, source, clazz, sink)
    context = Context.new( sink, clazz)
    template( name, source, context)
    context.close
  end
end
