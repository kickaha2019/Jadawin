require_relative 'image'

module Elements
  class Blurb < Element
    attr_reader :text

    def initialize( compiler, article, lines)
      @text = lines.join( ' ')
      if SPECIAL_CHARS =~ @text
        article.error( 'Bad characters in blurb')
        @discard = true
      end
      if @text.size > 50
        article.error( 'Blurb too long')
        @discard = true
      end
    end

    def page_content?
      false
    end

    def special?
      true
    end
  end
end