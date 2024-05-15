class Transpiler
  RESERVED_WORDS = ['or', 'and', 'true', 'false']

  class Context
    def initialize( sink, clazz)
      @io     = File.open( sink + '/' + clazz + '.rb', 'w')
      @io.puts <<"HEAD"
class #{clazz}
HEAD
      path = self.method(:close).source_location[0].sub( 'transpiler.rb', 'transpiled_methods.rb')
      IO.readlines( path).each do |line|
        @io.print line if /^\s/ =~ line
      end
      @indent = 0
      @rstrip = false
      @stack  = []
      @buffer = []
    end

    def close
      flush
      @io.puts "end"
      @io.close
    end

    def flush
      unless @buffer.empty?
        @io.puts( (' ' * @indent) + "h << \"#{@buffer.join('').gsub("\n","\\\\n").gsub('"',"\\\"")}\"")
      end
      @buffer = []
    end

    def indent( delta)
      flush
      @indent += delta
    end

    def indented
      @indent
    end

    def lstrip
      @buffer = [@buffer.join('').rstrip]
    end

    def pop
      @stack.pop
    end

    def print( text)
      flush
      @io.print( (' ' * @indent) + text)
      @rstrip = false
    end

    def push( action)
      @stack << action
    end

    def puts( text)
      print( text + "\n")
    end

    def rstrip( flag=true)
      @rstrip = true
    end

    def stacked( i=-1)
      @stack[-1]
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

      @buffer << text
    end
  end

  def initialize
    @error_location = nil
  end

  def handle_assign( tokens, context)
    if tokens[1] != '='
      raise 'Bad assign statement'
    end
    context.puts( "c[\"#{tokens[0]}\"] = " + handle_expression(tokens,2))
  end

  def handle_break( tokens, context)
    context.puts( 'break')
  end

  def handle_case( tokens, context)
    context.puts( 'case ' + handle_expression(tokens))
    context.indent( 4)
    context.rstrip
    context.push( 'case')
  end

  def handle_continue( tokens, context)
    context.puts( 'next')
  end

  def handle_else( tokens, context)
    if context.stacked == 'for'
      context.indent( -2)
      context.puts( 'end')
      context.puts( "unless looped#{context.indented}")
      context.indent( 2)
    else
      context.indent( -2)
      context.puts( 'else')
      context.indent( 2)
    end
  end

  def handle_elsif( tokens, context)
    context.indent( -2)
    context.puts( 'elsif ' + handle_expression(tokens))
    context.indent( 2)
  end

  def handle_endcase( tokens, context)
    context.indent( -4)
    context.puts( 'end')
    context.pop
  end

  def handle_endif( tokens, context)
    context.indent( -2)
    context.puts( 'end')
    context.pop
  end

  def handle_endfor( tokens, context)
    context.indent( -2)
    context.puts( 'end')
    context.puts "c[name#{context.indented}] = value#{context.indented}"
    context.pop
  end

  def handle_endunless( tokens, context)
    context.indent( -2)
    context.puts( 'end')
    context.pop
  end

  def handle_expression( tokens, offset=0)
    text, i = handle_expression2( tokens, offset)
    if i < tokens.size
      raise 'Unable to parse expression'
    end
    text
  end

  def handle_expression2(tokens, offset)
    i,handled = offset, []
    inside_filter = false

    while i < tokens.size
      token = tokens[i]
      break if [',',':',']'].include?( token)
      i += 1
      token = " #{token} " if RESERVED_WORDS.include?( token)

      if /^[a-z]/i =~ token
        handled << "x(c,'#{token}')"
      elsif token == '.'
        if tokens[i] == 'size'
          handled[-1] = handled[-1] + '.size'
        elsif /^[a-z]/i =~ tokens[i]
          handled[-1] = 'x(' + handled[-1] + ",'#{tokens[i]}')"
        else
          raise 'Bad . reference'
        end
        i += 1
      elsif token == '['
        ref, i = handle_expression2( tokens, i)
        if tokens[i] != ']'
          raise 'Bad [] expression'
        end
        handled[-1] = handled[-1] + "[#{ref}]"
        i += 1
      else
        if token == '|'
          if inside_filter
            handled << ')'
          end
          inside_filter = true
          handled.prepend( "f_#{tokens[i]}(")

          if tokens[i+1] == ':'
            i += 2
            handled << ','
          else
            i += 1
          end
        else
          handled << token
        end
      end
    end

    if inside_filter
      handled << ')'
    end

    return handled.join(''), i
  end

  def handle_for( tokens, context)
    context.puts "name#{context.indented}  = '#{tokens[0]}'"
    context.puts "value#{context.indented} = c['#{tokens[0]}']"
    context.puts "looped#{context.indented} = false"
    if tokens[1] != 'in'
      raise 'Unhandled for directive'
    end
    context.puts handle_expression(tokens, 2) + '.each do |loop|'
    context.indent( 2)
    context.puts "c['#{tokens[0]}'] = loop"
    context.puts "looped#{context.indented} = true"
    context.push( 'for')
  end

  def handle_if( tokens, context)
    context.puts( 'if ' + handle_expression(tokens))
    context.indent( 2)
    context.push( 'if')
  end

  def handle_render( tokens, context)
    context.puts( 'c1 = {}')
    from = 1
    from += 1 if tokens[from] == ','
    from += 1 if tokens[from] == 'with'

    while (from < tokens.size)
      raise 'Bad syntax in render directive' if tokens[from+1] != ':'
      expr, i = handle_expression2( tokens, from+2)
      context.puts( "c1['#{tokens[from]}'] = " + expr)
      i += 1 if tokens[i] == ','
      from = i
    end

    context.puts( "h << #{tokens[0][1..-2]}( c1)")
  end

  def handle_text( text, context)
    from = 0
    while ! (i = text.index( '{{', from)).nil?
      context.wrap_text( text[from...i]) if from < i
      tokens, j = tokenise( text, i+2, '}}')
      tokens, lstrip, rstrip = suppress_whitespace( tokens)
      context.lstrip if lstrip
      context.puts( 'h << "#{' + handle_expression( tokens) + '}"')
      context.rstrip if rstrip
      from = j
    end
    context.wrap_text( text[from..-1]) if from < text.size
  end

  def handle_unless( tokens, context)
    context.puts( 'unless ' + handle_expression(tokens))
    context.indent( 2)
    context.push( 'unless')
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
    return stanza, false, false if stanza.empty?
    lstrip = false

    if stanza[0] == '-'
      stanza = stanza[1..-1]
      lstrip = true
    elsif /^\-/ =~ stanza[0]
      stanza[0] = stanza[0][1..-1]
      lstrip = true
    end

    return stanza if stanza.empty?

    if stanza[-1] == '-'
      return stanza[0..-2], lstrip, true
    elsif /^\-/ =~ stanza[-1]
      stanza[-1] = stanza[-1][1..-1]
    end

    return stanza, lstrip, false
  end

  def template( name, text, context)
    begin
      context.indent(2)
      context.puts "def self.#{name}(c)"
      context.indent(2)
      context.puts 'h = []'

      stanzas( text) do |stanza|
        if stanza.is_a?( Array)
          stanza, lstrip, rstrip = suppress_whitespace( stanza)
          context.lstrip if lstrip
          unless stanza.empty?
            self.send( ('handle_' + stanza[0]).to_sym,

                       stanza[1..-1], context)
          end
          context.rstrip if rstrip
        else
          handle_text( stanza, context)
        end
      end

      context.puts "h.join('')"
      context.indent(-2)
      context.puts 'end'
      context.indent(-2)
    rescue Exception => bang
      puts "*** File:  #{name}"
      puts "*** Text:  #{@error_location}" if @error_location
      puts "*** Error: #{bang.message}"
      raise bang
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
      elsif /[,\[\]:]/ =~ text[i..i]
        tokens << text[i..i]
        from = i +1
      elsif /[0-9]/ =~ text[i..i]
        if j = text.index( /[^0-9\.]/i, i+1)
          tokens << text[i...j]
          from = j
        else
          raise "Missing #{stop}"
        end
      elsif /^\.[0-9]/ =~ text[i..(i+1)]
        if j = text.index( /[^0-9]/i, i+1)
          tokens << text[i...j]
          from = j
        else
          raise "Missing #{stop}"
        end
      elsif /[a-z_]/i =~ text[i..i]
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
