require_relative 'image'

module Elements
  class Blurb < Element
    attr_reader :text

    def initialize( compiler, article, lines)
      @text = lines.join( ' ')
      article.error( 'Bad characters in blurb') if SPECIAL_CHARS =~ @text
      article.error( 'Blurb too long') if @text.size > 50
    end

    def page_content?
      false
    end

    def special?
      true
    end
  end
end