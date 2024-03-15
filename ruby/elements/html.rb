module Elements
  class Html < Element
    def initialize( compiler, article, lines)
      @lines = lines
    end

    def line_count
      100
    end

    def to_data( compiler, article)
      {'type' => 'raw', 'text' => @lines.join( "\n")}
    end
  end
end