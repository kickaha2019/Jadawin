module Elements
  class Element
    SPECIAL_CHARS = /["<>`\*]/

    def initialize( article)
      @discard = false
    end

    def check_label( article, text)
      text1 = text.gsub( /[\*\[\]<>`]/, '')
      if text != text1
        article.error( 'Unexpected characters in ' + text)
      end
      text1
    end

    def discard?
      @discard
    end

    def ignore_error?( text)
      false
    end

    def image
      nil
    end

    def line_count
      0
    end

    def multiline?
      true
    end

    def page_content?
      true
    end

    def prepare( compiler, article, parents, younger)
    end

    def post_process_html( article, html)
      html
    end

    def special?
      false
    end

    def type_name
      self.class.name.split('::')[-1]
    end

    def wide?
      false
    end
  end
end