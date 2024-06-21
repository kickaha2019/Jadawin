module Elements
  class List < Element
    include Utils

    def initialize( compiler, article, lines)
      @list, @table = [], {}
      lines.each do |line|
        if m1 = /^(.*)\|(.*)$/.match( line)
          @table[check_label( article, m1[1].strip)] = Text.new( compiler, article, [m1[2].strip])
        elsif line.strip != ''
          @list << Text.new( compiler, article, [line.strip])
        end
      end

      if @list.empty?
        if @table.empty?
          article.error( 'Empty list')
        end
      elsif ! @table.empty?
        article.error( 'Bad list')
      end
    end

    def line_count
      3 + @list.size
    end

    def prepare( compiler, article, parents, younger)
      if @table.empty?
        @list.each do |text|
          text.prepare( compiler, article, parents, younger)
        end
      else
        @table.each_value do |text|
          text.prepare( compiler, article, parents, younger)
        end
      end
    end

    def to_data( compiler, article)
      if @table.empty?
        {'type'  => 'list',
         'rows'  => @list.collect do |value|
           {'data' => [value.to_data_single_paragraph( compiler, article)]}
         end
        }
      else
        {'type'  => 'table',
         'rows'  => @table.keys.collect do |key|
           text = @table[key].to_data_single_paragraph( compiler, article)
           [{'data' => [{'type' => 'raw', 'text' => key}], 'bold' => true,  'align' => 'left'},
            {'data' => [text], 'bold' => false, 'align' => 'left'}]
         end
        }
      end
    end
  end
end