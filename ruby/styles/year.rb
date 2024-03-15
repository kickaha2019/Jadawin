require_relative '../link'

module Styles
  class Year < Events
    include Utils

    @@articles_by_year = nil #Hash.new {|h,k| h[k] = []}

    def find_articles_by_year( article)
      return if article.is_a?( Link)

      if d = article.date
        @@articles_by_year[ d.year] << article
        return
      end

      article.children.each do |child|
        find_articles_by_year child
      end
    end

    def index_title( page)
      if d = page.date
        super( page) + d.strftime( " (%b&nbsp;#{d.day}#{format_ord(d.day)})")
      else
        super( page)
      end
    end

    def prepare( compiler, article, parents)
      if @@articles_by_year.nil?
        @@articles_by_year = Hash.new {|h,k| h[k] = []}
        find_articles_by_year parents[0]
      end

      unless /^\d{4}$/ =~ article.title
        article.error( "Expected year as title")
        return
      end

      existing_children_filenames = {}
      article.children.each do |child|
        existing_children_filenames[child.filename] = true
        d = child.date
        if d.nil?
          child.error( "Expected date")
        elsif d.year != article.title.to_i
          child.error( "Expected #{article.title} date")
        end
      end

      @@articles_by_year[article.title.to_i].each do |dated|
        unless existing_children_filenames[dated.filename]
          article.add_child ( Link.new( dated, dated))
        end
      end

      article
    end
  end
end
