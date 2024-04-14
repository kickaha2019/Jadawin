require_relative 'image'

module Elements
  class Title < Element
    attr_reader :text

    def initialize( compiler, article, lines)
      @text = lines[0]
      if SPECIAL_CHARS =~ @text
        article.error( 'Bad characters in title')
        @discard = true
      end
    end

    def multiline?
      false
    end

    def page_content?
      false
    end

    def special?
      true
    end
  end
end