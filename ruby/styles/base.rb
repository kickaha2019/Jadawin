require_relative '../utils'

module Styles
  class Base
    include Utils

    def image_index( compiler, article, page, image, dims)
      {'path'     => relative_path( article.filename, page.filename),
       'off_page' => page.off_page?,
       'blurb'    => ((page == self) ? false : page.blurb),
       'title'    => index_title(page),
       'details'  => image.details( compiler, article, dims, :prepare_thumbnail)}
    end

    def image_indexes( compiler, article, to_index)
      dims = compiler.dimensions( 'icon')

      children, icons = [], []
      to_index.each do |child|
        icon = child.icon
        if icon
          children << child
          icons    << icon
        else
          child.error( "No icon defined")
        end
      end

      entries = []
      scaled_dims = get_scaled_dims( dims, icons)

      children.each_index do |i|
        entries << image_index( compiler, article, children[i], icons[i], scaled_dims)
      end

      {'entries' => entries, 'dims' => scaled_dims}
    end

    def index?
      true
    end

    def index_title(page)
      prettify( page.title)
    end

    def leaf?( article)
      article.has_any_content?
    end

    def post_process_html( root_url, article, html)
      lines, inside_pre = [], false
      html.split( "\n").each do |line|
        if /<pre>/i =~ line
          article.error( '<pre> </pre> same HTML line') if /<\/pre>/i =~ line
          lines << line
          inside_pre = true
        elsif /<\/pre>/i =~ line
          lines << line
          inside_pre = false
        elsif inside_pre
          lines << line
        else
          line = line.strip.gsub( /\s\s/, ' ')
          lines << line unless line == ''
        end
      end
      lines.join( "\n")
    end

    def prepare( compiler, article, parents)
    end

    def render( compiler, parents, article, data)
      to_index = article.children.select {|a| a.style.index?}
      unless to_index.size == 0
        #article.error( 'Both content and children') if article.has_any_content?
        data['text_index']      = article.text_index( to_index, false)
        data['text_index_size'] = 'size0'
        data['image_index']     = image_indexes( compiler, article, to_index)
      end
    end

    def sort( articles)
      articles.sort do |a1,a2|
        t1   = a1.name
        t2   = a2.name
        comp = 0

        # Numbers on front of filenames win out in sorting
        if m1 = /^(\d+)(\D|$)/.match( t1)
          if m2 = /^(\d+)(\D|$)/.match( t2)
            comp = (m1[1].to_i <=> m2[1].to_i)
          else
            comp = -1
          end
        elsif m2 = /^(\d+)(\D|$)/.match( t2)
          comp = 1
        end

        # Lastly case insensitive sort on prettified titles moving words like
        # 'The' to end
        if comp == 0
          comp = (prettify_sort( a1.title) <=> prettify_sort( a2.title))
        end

        comp
      end
    end

    def stub( text)
      text.gsub( /[^\w\d]/, '_')
    end
  end
end
