require_relative 'Text'

module Elements
  class Table < Element
    include Utils

    def initialize( compiler, article, lines)
      @colums = @rows = []

      lines = lines.collect do |line|
        if m = /^\|(.*)$/.match( line)
          line = m[1]
        end
        if m = /^(.*)\|\s*$/.match( line)
          line = m[1]
        end
        line
      end

      @columns = lines[0].split( '|').collect do |column|
        check_label( article, column)
      end

      @rows = lines[1..-1].collect do |line|
        line.split('|').collect do |field|
          Text.new( compiler, article, (field.strip != '') ? [field] : [])
        end
      end
    end

    def columns
      @columns.collect do |column|
        {'data' => [{'type' => 'raw', 'text' => column}], 'bold' => true, 'align' => 'center'}
      end
    end

    def is_number?( markup)
      return false unless markup.size == 1
      /^\d+$/ =~ markup[0]['text']
    end

    def line_count
      5 + @rows.size
    end

    def prepare( compiler, article, parents, younger)
      @rows.each do |row|
        row.each do |column|
          column.prepare( compiler, article, parents, younger)
        end
      end
    end

    def row( compiler, article, r)
      fields = r.collect do |field|
        markup = field.to_data_single_paragraph( compiler, article)
        align = is_number?( markup) ? 'right' : 'left'
        {'data' => markup, 'bold' => false, 'align' => align}
      end

      while fields.size < @columns.size
        fields << {'data' => [{'type' => 'none'}], 'bold' => false, 'align' => 'left'}
      end

      fields
    end

    def rows( compiler, article)
      @rows.collect {|r| row( compiler, article, r)}
    end

    def to_data( compiler, article)
      {'type'  => 'table',
       'rows'  => [columns] + rows( compiler, article)}
    end
  end
end