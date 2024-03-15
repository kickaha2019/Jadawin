require_relative 'image'

module Elements
  class Inset < Image
    def line_count
      0
    end

    def overlay?
      true
    end

    def prepare( compiler, article, parents, younger)
      super
      okay = false

      younger.each do |sibling|
        if sibling.page_content?
          if sibling.respond_to?( :allow_for_inset)
            sibling.allow_for_inset
            okay = true
          end
          break
        end
      end

      unless okay
        article.error( 'Inset not followed by Text')
      end
    end

    def to_data( compiler, article)
      dims = get_scaled_dims( compiler.dimensions( 'icon'), [self])
      {'type'    => 'image',
       'clazz'   => ((@index % 2) == 0) ? 'left' : 'right',
       'overlay' => overlay( compiler, article),
       'id'      => anchor,
       'details' => details( compiler, article, dims,:prepare_thumbnail)
      }
    end
  end
end