module Elements
  class Text < Element
    include Utils

    attr_reader :line_count

    class Emphasized
      def initialize( text)
        @text = text.gsub( '<', '&lt;').gsub( '>', '&gt;')
      end

      def prepare( compiler, article)
        compiler.spell_check( article, @text)
      end

      def to_data( compiler, article)
        {'type' => 'emphasized', 'text' => @text}
      end

      def to_html( compiler, article)
        '<EM>' + @text +'</EM>'
      end
    end

    class Linkage
      @@targets  = Hash.new {|h,k| h[k] = []}

      def initialize( text, url=nil)
        @text = text.gsub( '<', '&lt;').gsub( '>', '&gt;')
        @url  = url
        @@targets[text] << url if url
      end

      def prepare( compiler, article)
        compiler.spell_check( article, @text)

        unless @url
          case @@targets[@text].uniq.size
          when 0
            article.error( 'Undefined target: ' + @text)
          when 1
            @url = @@targets[@text][0]
          else
            article.error( 'Ambiguous target: ' + @text)
          end
        end

        if @url
          unless /^(http|https|mailto):/ =~ @url
            ref, err = compiler.lookup( @url, @url)
            if err
              article.error( err)
              @url = nil
            else
              @url = article.relative_path( article.filename, ref.is_a?( String) ? ref : ref.filename)
            end
          end
        end
      end

      def to_data( compiler, article)
        {'type'    => 'link',
         'offsite' => compiler.offsite?( @url),
         'url'     => @url,
         'text'    => @text}
      end

      def to_html( compiler, article)
        return '' unless @url

        "<A HREF=\"#{@url}\"" +
        (compiler.offsite?( @url) ? ' target="_blank" rel="nofollow"' : '') +
        '>' +
        @text +
        '</A>'
      end
    end

    class Normal
      def initialize( text)
        @text = text.gsub( '<', '&lt;').gsub( '>', '&gt;')
      end

      def prepare( compiler, article)
        compiler.spell_check( article, @text)
      end

      def to_data( compiler, article)
        {'type' => 'normal', 'text' => @text}
      end

      def to_html( compiler, article)
        @text
      end
    end

    class Raw
      def initialize( text)
        @text = text.gsub( '&', '&amp;').gsub( '<', '&lt;').gsub( '>', '&gt;')
      end

      def prepare( compiler, article)
      end

      def to_data( compiler, article)
        {'type' => 'code', 'text' => @text}
      end

      def to_html( compiler, article)
        '<SPAN CLASS="code">' + @text +'</SPAN>'
      end
    end

    def initialize( compiler, article, lines)
      super( article)
      #@lines     = lines
      @min_lines  = 0
      @line_count = lines.join( ' ').size / 60

      @paragraphs = []
      @paragraphs << (paragraph = [])
      lines.each do |line|
        if line.strip == ''
          @paragraphs << (paragraph = [])
        else
          parse( article, line, paragraph)
        end
      end
    end

    def link_atts( url)
      if /alofmethbin\.com\// =~ url
        ''
      elsif /^http/ =~ url
        'target=“_blank” rel=“nofollow” '
      else
        ''
      end
    end

    def paragraph_to_data( compiler, article, paragraph)
      paragraph.collect {|fragment| fragment.to_data( compiler, article)}
    end

    def paragraph_to_html( compiler, article, paragraph)
      paragraph.collect {|fragment| fragment.to_html( compiler, article)}.join('')
    end

    def parse( article, text, paragraph)
      while m = /^([^`\*\[]*)([`\*\[])(.*)$/.match( text)
        paragraph << Normal.new( m[1]) if m[1] != ''
        case m[2]
        when '`'
          text = parse_code( article, m[3], paragraph)
        when '*'
          text = parse_emphasized( article, m[3], paragraph)
        else
          text = parse_link( article, m[3], paragraph)
        end
      end

      paragraph << Normal.new( text + "\n")
    end

    def parse_code( article, text, paragraph)
      if m = /^([^`]*)`(.*)$/.match( text)
        article.error( 'Empty inline code segment') if m[1].strip == ''
        paragraph << Raw.new(m[1])
        m[2]
      else
        article.error( 'Bad `` subtext')
        ''
      end
    end

    def parse_emphasized( article, text, paragraph)
      if m = /^([^\*]*)\*(.*)$/.match( text)
        article.error( 'Empty emphasized segment') if m[1].strip == ''
        paragraph << Emphasized.new( m[1])
        m[2]
      else
        article.error( 'Bad ** subtext')
        ''
      end
    end

    def parse_link( article, text, paragraph)
      if m = /^([^\]]*)\](.*)$/.match( text)
        article.error( 'Empty link text') if m[1].strip == ''
        if /^\(/ =~ m[2]
          if m1 = /^([^\)]*)\)(.*)$/.match( m[2][1..-1])
            paragraph << Linkage.new( check_label( article, m[1]), m1[1])
            m1[2]
          else
            article.error( 'Bad [] subtext')
            ''
          end
        else
          paragraph << Linkage.new( check_label( article, m[1]))
          m[2]
        end
      else
        article.error( 'Bad [] subtext')
        ''
      end
    end

    def prepare( compiler, article, parents, younger)
      @paragraphs.each do |paragraph|
        paragraph.each do |unit|
          unit.prepare( compiler, article)
        end
      end
    end

    def to_data( compiler, article)
      out = @paragraphs.collect do |paragraph|
         paragraph_to_data( compiler, article, paragraph)
      end

      {'type'       => 'paragraphs',
       'paragraphs' => out}
    end

    def to_data_single_paragraph( compiler, article)
      paragraph_to_data( compiler, article, @paragraphs[0])
    end

    def to_html( compiler, article)
      out = @paragraphs.collect do |paragraph|
        paragraph_to_html( compiler, article, paragraph)
      end

      missing_lines = @min_lines - @line_count
      while missing_lines > 0
        missing_lines -= 1
        out[-1] += '<BR>'
      end

      {'type' => 'raw',
       'text' => '<P>' + out.join( '</P><P>') + '</P>'}
    end

    def to_html_single_paragraph( compiler, article)
      {'type' => 'raw', 'text' => paragraph_to_html( compiler, article, @paragraphs[0])}
    end
  end
end