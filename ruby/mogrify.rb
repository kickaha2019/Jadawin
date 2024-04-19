class Mogrify
  class Function
    attr_reader   :callers
    attr_accessor :arguments

    def initialize( args)
      @callers   = []
      @arguments = args
      @inline    = false
    end

    def add_caller( caller)
      @callers << caller unless @callers.include?( caller)
    end

    def arguments?
      ! @arguments.empty?
    end
  end

  def initialize( source, sink)
    @source    = source
    @sink      = sink
    @functions = {}
  end

  def default_page_argument
    @functions.keys.each do |key|
      fun = @functions[key]
      unless fun.arguments?
        fun.arguments = ['page']
      end
    end

    sources do |name, lines|
      unless @functions[name]
        @functions[name] = Function.new( ['page'])
      end
    end
  end

  def determine_arguments
    sources do |name, lines|
      lines.each do |line|
        line.scan( /^(.*){%\s*include\s*'([^']*)'\s*(?:with|,)\s*([^%]*)\s*%}(.*)$/) do |match|
          fun  = match[1]
          args = match[2].strip.split(',')

          if (args.size > 0) || (/:/ =~ args[0])
            args = args.collect do |arg|
              if m1 = /^(.*):/.match( arg)
                m1[1].strip
              else
                fun
              end
            end
          else
            args = [fun]
          end

          if old = @functions[fun]
            if ok = (old.arguments.size == args.size)
              (0..(old.arguments.size)).each do |i|
                ok = false if old.arguments[i] != args[i]
              end
            end

            unless ok
              puts "*** #{name}: Arguments mismatch for #{fun} with #{old.callers}"
              p old
              p args
              raise 'Dev'
            end

            @functions[fun].add_caller( name)
          else
            @functions[fun] = Function.new( args)
            @functions[fun].add_caller( name)
          end
        end

        line.scan( /^(.*){%\s*include\s*'([^']*)'\s*%}(.*)$/) do |match|
          fun = match[1].strip
          if old = @functions[fun]
            unless old[1].size == 0
              puts "*** #{name}: Arguments mismatch for #{fun} with #{old[0]}"
            end
            @functions[fun].add_caller( name)
          else
            @functions[fun] = Function.new( [])
            @functions[fun].add_caller( name)
          end
        end
      end
    end
  end

  def elide_dimension_arguments
    @functions.values.each do |info|
      info.arguments.delete( 'dimensions')
    end
  end

  def find_config_uses
    sources do |name, lines|
      lines.each do |line|
        line.scan( /{{([^}]*)}}/) do |match|
          if /(dimension|colour|width)/ =~ match[0]
            force_config_argument( name)
          end
        end
      end
    end
  end

  def force_config_argument( fun)
    info = @functions[fun]
    if (! info.arguments?) || (info.arguments[0] != 'config')
      info.arguments = ['config'] + info.arguments
      info.callers.each do |caller|
        force_config_argument( caller)
      end
    end
  end

  def mogrify
    @functions.each_pair do |key, info|
      p [key, info.inline, info.callers, info.arguments]
    end
  end

  def sources
    Dir.entries( @source).each do |f|
      if m = /^(.*)\.liquid$/.match( f)
        lines, inside, compound = [], false, ''
        IO.readlines( @source + '/' + f).each do |line|
          if inside
            compound = compound + ' ' + line
            if /%}\s*$/ =~ line
              lines << compound
              inside = false
            end
          elsif /^\s*{%/ =~ line
            if /%}\s*$/ =~ line
              lines << line
              inside = false
            else
              compound = line
              inside   = true
            end
          else
            lines << line
          end
        end
        yield m[1], lines
      end
    end
  end
end

m = Mogrify.new( ARGV[0], ARGV[1])
m.determine_arguments
m.default_page_argument
m.find_config_uses
m.elide_dimension_arguments
m.mogrify