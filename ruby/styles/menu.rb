require_relative '../link'

module Styles
  class Menu < Base
    def format_entries( entries)
      entries.each do |entry|
        entry['title'] = format_text( entry['title'])
        entry['blurb'] = format_text( entry['blurb'])
      end
      entries
    end

    def format_text( text)
      words = []
      word  = nil
      text.split( ' ').each do |w|
        if word.nil?
          word = w
        elsif (word + w).size > 7
          words << word
          word  =  w
        else
          word = word + ' ' + w
        end
      end
      words << word

      return words.join( '<BR>') if words.size < 3

      best, _ = format_text_1( words,3)
      best
    end

    def format_text_1( words, splits)
      if splits < 2
        text = words.join( ' ')
        return text, measure_text( text)
      end

      if words.size <= splits
        len = 0
        words.each do |w|
          l = measure_text( w)
          len = l if l > len
        end
        return words.join( '<BR>'), len
      end

      text = words.join( ' ')
      len  = measure_text( text)
      overall_len = len - splits * measure_text( ' ')

      (0...(words.size)).each do |i|
        len = measure_text( words[0..i].join( ' '))
        if len > overall_len / splits
          t, w = format_text_1( words[(i+1)..-1], splits-1)
          if i < 1
            t1, w1, len1 = '', 1000000, 0
          else
            t1, w1 = format_text_1( words[i..-1], splits-1)
            len1 = measure_text( words[0...i].join( ' '))
          end

          offset = i
          if max( len, w) > max( len1, w1)
            len, t, w, offset = len1, t1, w1, i-1
          end
          return words[0..offset].join( ' ') + '<BR>' + t, max( len, w)
        end
      end

      return words.join( '<BR>'), len
    end

    def leaf?( article)
      false
    end

    def max( x,y)
      (x < y) ? y : x
    end

    def measure_entries( entries, key)
      entries.inject( 1) do |width1, entry|
        text_width = measure_entry( entry, key)
        (width1 < text_width) ? text_width : width1
      end
    end

    def measure_entry( entry, key)
      entry[key].split('<BR>').inject( 1) do |width2, line|
        len = measure_text( line)
        (width2 < len) ? len : width2
      end
    end

    def measure_text( text)
      len = 0
      text1 = text.gsub( /[ilI\:']/) do
        len += 0.5
        ''
      end
      text1 = text1.gsub( /[mMwW]/) do
        len += 1.5
        ''
      end
      text1.size + len
    end

    def min( x,y)
      (x < y) ? x : y
    end

    def rect_indexes( compiler, article)
      srand( Digest::SHA1.hexdigest( article.filename).to_i(16))

      entries = article.children.select {|a| a.style.index?}.collect do |child|
        {'path'     => relative_path( article.filename, child.filename),
         'title'    => prettify( child.title),
         'off_page' => child.off_page?,
         'blurb'    => (child.blurb ? child.blurb : prettify( child.title))}
      end

      entries         = format_entries( entries)
      max_title_width = measure_entries( entries, 'title')

      style_entries( compiler, entries, max_title_width)

      {'entries'         => entries,
       'title_width'     => max_title_width}
    end

    def render( compiler, parents, article, data)
      if article.has_any_content?
        article.error( 'Menu has content')
      end
      data['rect_index']      = rect_indexes( compiler, article)
    end

    def style_entries( compiler, entries, max_title_width)
      n_styles = compiler.get_config( 'num_menu_styles')
      strides  = ([1] + compiler.get_config( 'menu_items_per_line')).uniq

      entries.each_index do |i|
        used = {}
        strides.each do |j|
          if (i-j) >= 0
            used[entries[i-j]['style']] = true
          end
        end

        poss = []
        (0...n_styles).each do |j|
          poss << j unless used[j]
        end

        if i == 0
          colour = 0
        else
          colour = poss[rand(poss.size)]
        end
        entries[i]['style'] = colour

        blurb_width = measure_entry( entries[i], 'blurb')
        if blurb_width <= max_title_width
          blurb_width = max_title_width
          entries[i]['blurb_large'] = true
        end

        entries[i]['blurb_width'] = blurb_width
      end
    end
  end
end
