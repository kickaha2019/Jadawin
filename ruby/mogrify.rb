class Mogrify
  def initialize( source, sink)
    @source    = source
    @sink      = sink
    @arguments = {}
  end

  def determine_arguments
    sources do |name, lines|
      lines.each do |line|
        if m = /{%\s*include\s*'([^']*)'\s*(with|,)\s*([^%]*)\s*%}/.match( line)
          args = m[2].split(',')
          if (args.size > 1) || (/:/ =~ args[0])
            args = args.collect do |arg|
              if m1 = /^(.*):/.match( arg)
                m1[1]
              else
                puts "*** #{name}: Bad argument for #{m[1]}"
                '?'
              end
            end
          else
            args = ['data']
          end

          if old = @arguments[m[1]]
            if ok = (old[1].size == args.size)
              (0..(old[1].size)).each do |i|
                ok = false if old[1][i] != args[i]
              end
            end

            unless ok
              puts "*** #{name}: Arguments mismatch for #{m[1]} with #{old[0]}"
            end
          else
            @arguments[m[1]] = [name, args]
          end
        elsif m2 = /{%\s*include\s*'([^']*)'\s*%}/.match( line)
          if old = @arguments[m2[1]]
            unless old[1].size == 0
              puts "*** #{name}: Arguments mismatch for #{m2[1]} with #{old[0]}"
            end
          else
            @arguments[m2[1]] = [name, []]
          end
        end
      end
    end
  end

  def mogrify
    @arguments.each_pair do |key, value|
      p [key, value[1]]
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
m.mogrify