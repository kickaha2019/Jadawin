module Styles
  class Events < Base
    def leaf?( article)
      false
    end

    def sort( articles)
      no_dates = articles.select {|a| a.date.nil?}
      if no_dates.size > 1
        no_dates.each do |a|
          a.error( "Expected date")
        end
      end

      articles.sort do |a1,a2|
        if a1.date.nil?
          1
        elsif a2.date.nil?
          -1
        else
          (a1.date <=> a2.date)
        end
      end
    end
  end
end
