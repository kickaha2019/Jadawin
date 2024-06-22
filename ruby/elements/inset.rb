require_relative 'image'

module Elements
  class Inset < Image
    def line_count
      0
    end

    def prepare( compiler, article, parents, younger)
      super
      okay = false

      younger.each do |sibling|
        if sibling.page_content?
          okay = true
          break
        end
      end

      unless okay
        article.error( 'Inset not followed by another element')
      end
    end

    def to_data( compiler, article)
      dims = get_scaled_dims( compiler.dimensions( 'icon'), [self])
      {'type'    => 'inset',
       'overlay' => overlay( compiler, article),
       'details' => details( compiler, article, dims,:prepare_thumbnail)
      }
    end
  end
end