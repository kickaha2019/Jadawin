require_relative '../utils'

module Elements
  class Links < Element
    include Utils

    def initialize( compiler, article, tag)
      @tag = tag[0]
    end

    def multiline?
      false
    end

    def page_content?
      false
    end

    def prepare( compiler, article, parents, younger)
      refs = Tag.find( @tag)
      if refs.size == 0
        article.error( "Unknown tag: #{@tag}")
      end

      refs.each do |ref|
        ref.render
        article.add_child( Link.new( article, ref)) if ref.publish?
        ref.set_origin( parents + [article])
      end
    end
  end
end