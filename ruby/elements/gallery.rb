require_relative 'image'

module Elements
  class Gallery < Element
    include Utils

    def initialize( compiler, article, lines)
      super( article)
      @images, @labels = [], []
      lines.each do |line|
        if m = /^(\S+)\s+(.*)$/.match( line)
          @images << Image.new( compiler, article, [m[1]])
          @labels << Text.new( compiler, article, [m[2]])
        elsif line.strip != ''
          article.error( 'No label for ' + line.strip)
        end
      end
    end

    def image
      @images[0]
    end

    def line_count
      5 * ((@images.size + 7) / 8).to_i
    end

    def prepare( compiler, article, parents, younger)
      @labels.each do |text|
        text.prepare( compiler, article, parents, younger)
      end
    end

    def to_data( compiler, article)
      icon_dims = get_scaled_dims( compiler.dimensions( 'icon'), @images)

      entries = []
      @images.each_index do |i|
        entries << {'tag'     => [@labels[i].to_data_single_paragraph( compiler, article)],
                    'overlay' => @images[i].overlay( compiler, article),
                    'details' => @images[i].details( compiler, article, icon_dims, :prepare_thumbnail)}
      end

      {'type'   => 'gallery',
       'dims'   => icon_dims,
       'images' => entries}
    end
  end
 end