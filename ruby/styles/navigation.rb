require_relative '../link'

module Styles
  class Navigation < Base
    def initialize( article, before, after)
      @wrap   = article.styled? ? article.style : nil
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

      if @wrap
        @wrap.render( compiler, parents, article, data)
      else
        unless article.has_any_content?
          super
        end
      end
    end
  end
end
