require_relative '../utils'

module Elements
  class Css < Element
    include Utils

    def initialize( compiler, article, lines)
      @lines = lines
    end

    def to_data( compiler, article)
      {'type' => 'css', 'text' => @lines.join( "\n")}
    end
  end
end