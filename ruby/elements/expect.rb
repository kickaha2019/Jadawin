require_relative '../utils'

module Elements
  class Expect < Element
    include Utils

    @@number_of_tests = 0

    def initialize( compiler, article, lines)
      @@number_of_tests += 1
      if lines.size != 2
        article.error( 'Bad expect directive')
        @title, @regex = '', /./
      else
        @title = lines[0]
        expr, @negate = lines[1], false
        if m = /^\!(.*)$/.match( expr)
          expr, @negate = m[1], true
        end
        @regex = Regexp.new( expr.strip, Regexp::MULTILINE)
      end
    end

    def self.number_of_tests
      @@number_of_tests
    end

    def page_content?
      false
    end

    def post_process_html( article, html)
      if @regex =~ html
        article.error( @title) if @negate
      else
        article.error( @title) unless @negate
      end
      html
    end
  end
end