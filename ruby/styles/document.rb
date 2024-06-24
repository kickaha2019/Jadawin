require_relative 'events'
require_relative 'navigation'

module Styles
  class Document < Base
    def prepare( compiler, article, parents)
      prev = article.has_any_content? ? article : nil
      article.children.each_index do |i|
        child = article.children[i]
        child.override_style( Navigation.new( child, prev, article.children[i+1]))
        prev  = child
      end
    end
    # def prepare( compiler, article, parents)
    #   article.children.each do |child|
    #     unless child.styled? || child.children?
    #       child.override_style( TextIndex.new)
    #     end
    #   end
    #   article
    # end

    def render( compiler, parents, article, data)
      data['index_style'] = 'document' if article.has_any_content?
      data['text_index']  = article.text_index( article.children)
    end
  end
end
