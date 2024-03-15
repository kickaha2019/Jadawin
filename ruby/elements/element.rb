module Elements
  class Element
    SPECIAL_CHARS = /["<>`\*]/

    attr_reader :index
    @@next_index = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}

    def initialize( article)
      @index   = next_index( self.class.name, article)
      @discard = false
    end

    def backstop( * args)
      args.each do|arg|
        return arg if arg
      end
      nil
    end

    def check_label( article, text)
      if /[\*\[\]<>`]/ =~ text
        article.error( 'Unexpected characters in ' + text)
      end
      text
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

    def impact( article, other)
    end

    def line_count
      0
    end

    def multiline?
      true
    end

    def next_index( type, article)
      @@next_index[type][article.filename] += 1
    end

    def overlay?
      false
    end

    def page_content?
      true
    end

    def prepare( compiler, article, parents, younger)
    end

    def post_process_html( article, html)
      html
    end

    def replace( assign)
      nil
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