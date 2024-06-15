require_relative '../link'

module Styles
  class News < Base
    def find_dated_articles( article, found)
      return if article.is_a?( Link)

      if article.date && article.leaf?
        found << article
      end

      unless article.leaf?
        article.children.each do |child|
          find_dated_articles( child, found)
        end
      end
    end

    def prepare( compiler, article, parents)
      if article.date
        article.error( 'News style article must not be dated')
        return
      end

      if article.children?
        article.error( 'News style article must not have children')
      end

      dated_articles = []
      find_dated_articles( parents[-1], dated_articles)
      dated_articles = dated_articles.uniq.sort_by do |dated|
        dated.date
      end

      if dated_articles.size > 30
        dated_articles = dated_articles[-30..-1]
      end

      dated_articles.reverse.each do |dated|
        title = dated.title + dated.date.strftime( ' (%b %Y)')
        article.add_child( Link.new( dated, dated, title))
      end
    end

   def sort( articles)
     articles.sort_by do |dated|
       - dated.date.to_i
     end
   end
  end
end
