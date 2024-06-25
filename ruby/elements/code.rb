module Elements
  class Code < Element
    def initialize( compiler, article, lines)
      super( article)
      shortest_leading_spaces = 100
      lines.each do |line|
        if m = /^(\s*)\S/.match( line)
          if shortest_leading_spaces > m[1].size
            shortest_leading_spaces = m[1].size
          end
        end
      end

      @lines = lines.collect do |line|
        line[shortest_leading_spaces..-1]
      end
    end

    def line_count
      100
    end

    def to_data( compiler, article)
      {'type'  => 'code',
       'text'  => @lines.join( "\n") + "\n"}
    end
  end
end