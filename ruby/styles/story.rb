require_relative 'events'

module Styles
  class Story < Events
    class Navigation < Base
      def initialize( before, after)
        @before = before
        @after  = after
      end

      def render( compiler, parents, article, data)
        if @before
          data['previous_page'] = relative_path( article.filename, @before.filename)
        end
        if @after
          data['next_page'] = relative_path( article.filename, @after.filename)
        end

        unless article.has_any_content?
          super
        end
      end
    end

    def leaf?( article)
      true
    end

    def prepare( compiler, article, parents)
      prev = article.has_any_content? ? article : nil
      article.children.each_index do |i|
        child = article.children[i]
        child.override_style( Navigation.new( prev, article.children[i+1]))
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
