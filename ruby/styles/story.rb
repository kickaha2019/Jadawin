require_relative 'events'

require_relative 'navigation'

module Styles
  class Story < Events
    def leaf?( article)
      true
    end

    def prepare( compiler, article, parents)
      prev = article.has_any_content? ? article : nil
      article.children.each_index do |i|
        child = article.children[i]
        child.override_style( Navigation.new( child, prev, article.children[i+1]))
        prev  = child
      end
    end

    def render( compiler, parents, article, data)
      if article.has_any_content?
        if article.children?
          data['next_page']   = relative_path( article.filename, article.children[0].filename)
          if article.children.size > 1
            data['story_index'] = article.text_index( article.children)
          end
        end
      else
        super
      end
    end
  end
end
