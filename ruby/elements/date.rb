require_relative 'image'

module Elements
  class Date < Element
    include Utils
    attr_reader :date

    def initialize( compiler, article, text)
      super( article)
      @first = article.date.nil?
      @date  = convert_date( article, text[0])
    end

    def convert_date( article, text)
      day = -1
      month = -1
      year = -1

      text.split.each do |el|
        i = el.to_i
        if i >= 1800
          year = i
        elsif (i > 0) && (i < 32)
          day = i
        else
          if i = ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"].index( el[0..2].downcase)
            month = i + 1
          end
        end
      end

      if (day > 0) && (month > 0) && (year > 0)
        Time.gm( year, month, day)
      else
        article.error( "Bad date [#{text}]")
        nil
      end
    end

    def discard?
      @date.nil?
    end

    def multiline?
      false
    end

    def page_content?
      ! @first
    end

    def special?
      @first
    end

    def to_data( compiler, article)
      {'type'  => 'heading',
       'index' => @index,
       'text'  => format_date( @date)}
    end
  end
 end