require_relative '../utils'

module Elements
  class Error < Element
    include Utils

    @@errors = []

    def initialize( compiler, article, lines)
      @@errors << self
      @article = article
      @matched = false
      if lines.size != 2
        article.error( 'Bad error directive')
        @title, @match = '', ''
      else
        @title, @match = lines[0], lines[1].strip
      end
    end

    def ignore_error?( text)
      if (! @matched) && (@match == text)
        @matched = true
      else
        false
      end
    end

    def self.number_of_tests
      @@errors.size
    end

    def page_content?
      false
    end

    def report_error
      @article.error( 'Not caught: ' + @title) unless @matched
    end

    def self.report_errors
      @@errors.each {|error| error.report_error}
    end
  end
end