require 'fileutils'

module Elements
  class SVG < Element
    include Utils

    def initialize( compiler, article, source)
      super( article)
      path        = compiler.source_filename( abs_filename( article.filename, source))
      svg         = IO.read( path)
      @text_index = text_index( svg)
      @svg        = reduce_svg( svg)
    end

    def reduce_svg( xml)
      xml.gsub( /<\?[^>]*\?>/, '').gsub( / version="[^"]*"/, '').gsub( / title="[^"]*"/, '')
    end

    def text_index( source)
      index = 0
      source.scan( /<a[^>]*>/mi).collect do |anchor|
         index += 1
         {'path'     => anchor.match( /href="([^"]*)"/)[1],
          'off_page' => false,
          'title'    => anchor.match( /title="([^"]*)"/)[1],
          'index'    => index
         }
       end.sort_by {|entry| entry['title']}
    end

    def to_data( compiler, article)
      background = nil

      fills = @svg.scan( / fill="([^"]*)"/mi)
      background = fills[0][0] unless fills.empty?

      unless background
        background = 'cyan'
        article.error( "No background found for SVG map")
      end

      if m = / width="([^"]*)"/mi.match( @svg)
        width = m[1].to_i
      else
        width = 1024
        article.error( "No width found for SVG map")
      end

      {'type'            => 'svg',
       'index'           => @index,
       'background'      => background,
       'text_index'      => @text_index, #article.text_index( article.children),
       'width'           => width,
       'source'          => @svg}
    end

    def wide?
      true
    end
  end
 end