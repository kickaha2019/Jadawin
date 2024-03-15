require_relative 'events'

module Styles
  class TextIndex < Events
    def render( compiler, parents, article, data)
      data['index_style'] = 'document' if article.has_any_content?
      data['text_index']  = article.text_index( parents[-1].children)
    end
  end

  class Document < Base
    def prepare( compiler, article, parents)
      article.children.each do |child|
        unless child.styled? || child.children?
          child.override_style( TextIndex.new)
        end
      end
      article
    end

    def render( compiler, parents, article, data)
      data['index_style'] = 'document' if article.has_any_content?
      data['text_index']  = article.text_index( article.children)
    end
  end
end
