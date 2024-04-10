require 'fileutils'
require "vips"

require_relative 'element'
require_relative '../utils'

module Elements
  class Image < Element
    include Utils
    @@advices = {}
    attr_reader :height, :width, :tag, :source

    def initialize( compiler, article, source)
      super( article)
      source = source[0]

      if source.nil?
        article.error( type_name + ' missing image name')
        return
      elsif /;/ =~ source
        source, advice = * source.split(';')
        unless ['top','bottom','left','right'].include?( advice)
          article.error( "Unsupported image annotation: #{advice}")
          advice = nil
        end
      else
        advice = nil
      end

      unless /\.(png|jpg|jpeg|gif|webp)$/i =~ source
        article.error( 'Not an image file: ' + source)
        return
      end

      @tag = prettify( source.split('/')[-1].split('.')[0])

      source1 = (/^\// =~ source) ? source : abs_filename( article.filename, source)
      unless @@image_cache[source1]
        if File.exist?( compiler.source_filename( source1))
          article.error( 'Case mismatch for ' + source)
        else
          article.error( 'File not found: ' + source)
        end
        return
      end

      @source = compiler.source_filename( source1)
      @sink   = compiler.sink_filename( source1)
      if advice
        if @@advices[@source]
          article.error( "Inconsistent advice for image: #{source}") unless advice == @@advices[@source]
        else
          @@advices[@source] = advice
        end
      end

      info = @@image_cache[source1]
      if info['width'] < 1
        article.error( 'Badly formatted image file: ' + source)
        return
      end

      @width     = info['width']
      @height    = info['height']
      @timestamp = info['timestamp']
    end

    def anchor
      image ? "I#{image.index}" : nil
    end

    def constrain_dims( tw, th, w, h)
      if w * th >= h * tw
        if w > tw
          h = (h * tw) / w
          w = tw
        end
      else
        if h > th
          w = (w * th) / h
          h = th
        end
      end

      return w, h
    end

    def create_directory( path)
      path = File.dirname( path)
      unless File.exist?( path)
        create_directory( path)
        Dir.mkdir( path)
      end
    end

    def details( compiler, article, dims, prepare)
      image_file, target_dims = prepare_image( dims, prepare)
      return nil unless image_file
      compiler.record( image_file)
      {'path'  => relative_path( compiler.sink_filename( article.filename), image_file),
       'dims'  => target_dims,
       'tag'   => prettify(image.tag)}
    end

    def discard?
      error?
    end

    def error?
      @width.nil?
    end

    def self.find_images( source)
      cache_path    = source + '/_images.yaml'
      @@image_cache = {}

      if File.exist?( cache_path)
        YAML.load( IO.read( cache_path)).each do |cached|
          cached['found']   = false
          @@image_cache[ cached['path']] = cached
        end
      end

      find_images1( source, '')

      File.open( cache_path, 'w') do |io|
        io.puts @@image_cache.values.select {|e| e['found']}.to_yaml
      end
    end

    def self.find_images1( source, dir)
      Dir.entries( source + dir).each do |f|
        next if /^[\._]/ =~ f
        path = ((dir == '/') ? '' : dir) + '/' + f
        if File.directory?( source + path)
          find_images1( source, path)
        elsif /\.(jpg|jpeg|png|gif|svg|webp)$/i =~ f
          cached    = @@image_cache[path]
          if cached.nil?
            @@image_cache[path] = cached = {'path' => path, 'timestamp' => -1}
          end

          timestamp = File.mtime( source + path).to_i
          if timestamp != cached['timestamp']
            begin
              w,h,o = * get_image_dims( source + path)
            rescue
              w = h = -1
              o = 0
            end
            cached['timestamp'] = timestamp
            cached['height']    = h
            cached['width']     = w
            cached['orient']    = o
          end

          cached['found']     = true
        end
      end
    end

    def self.get_image_dims( filename)
      im     = Vips::Image.new_from_file filename, access: :sequential
      width  = im.get('width')
      height = im.get('height')
      orient = 0

      if im.get_fields.include?( 'exif-ifd0-Orientation')
        if /^[4567]/ =~ (orient = im.get( 'exif-ifd0-Orientation')[0..0])
          width, height = height, width
        end
      end

      return width, height, orient.to_i
    end

    def image
      error? ? nil : self
    end

    def line_count
      10
    end

    def multiline?
      false
    end

    def overlay( compiler, article)
      dims = get_scaled_dims( compiler.dimensions( 'overlay'), [self])
      path, _ = prepare_image( dims, :prepare_source_image)
      compiler.record( path)
      relative_path( compiler.sink_filename( article.filename), path)
    end

    def page_content?
      true
    end

    def prepare_image( dims, prepare, * args)
      target_dims, file = [], nil
      dims.reverse.each do |dim|
        f, w, h = self.send( prepare, file, * dim, * args)
        file = f unless file
        target_dims << [w,h]
      end
      return file, target_dims.reverse
    end

    def prepare_images( dims, prepare, * args)
      sizes, file, dims = '', nil, dims.reverse
      (0...dims.size).each do |i|
        sizes = sizes + " size#{dims.size - i - 1}"
        if ((i+1) >= dims.size) || (dims[i][0] != dims[i+1][0]) || (dims[i][1] != dims[i+1][1])
          f, w, h = self.send( prepare, file, * dims[i], * args)
          file = f unless file
          yield file, w, h, sizes if file
          sizes = ''
        end
      end
    end

    def prepare_source_image( imagefile, width, height)
      return nil, width, height unless @width && @height
      w,h = constrain_dims( width, height, @width, @height)
      m = /^(.*)(\.\w*)$/.match( @sink)
      imagefile = m[1] + "-#{@timestamp}-#{w}-#{h}" + '.webp' unless imagefile

      unless File.exist?( imagefile)
        create_directory( imagefile)
        im = Vips::Image.thumbnail( @source, w, height: h)
        save_image( im, imagefile)
      end

      return imagefile, w, h
    end

    def prepare_thumbnail( thumbfile, width, height)
      return nil, width, height unless @height && @width
      w,h,x,y = shave_thumbnail( width, height, @width, @height)
      m = /^(.*)(\.\w*)$/.match( @sink)
      unless m
        raise 'Internal error'
      end
      advice = @@advices[@source]

      unless thumbfile
        thumbfile = m[1] + "-#{@timestamp}-#{width}-#{height}" + (advice ? "-#{advice}" : '-centre') + '.webp'
      end

      unless File.exist?( thumbfile)
        im = Vips::Image.new_from_file @source, access: :sequential
        im = im.crop( x, y, w, h).resize( (1.0 * width) / @width)
        save_image( im, thumbfile)
      end

      return thumbfile, width, height
    end

    def same_source( other)
      @source == other.source
    end

    def save_image( image, file)
      if /\.webp$/ =~ file
        image.write_to_file( file, Q: 65, effort: 6, mixed: true, strip: true)
      else
        image.write_to_file( file, compression: 9, Q: 65, effort: 10, strip: true)
      end
    end

    def scaled_height( dim)
      return dim[1] unless @height && @width
      sh = (dim[0] * @height + @width - 1) / @width
      (sh > dim[1]) ? sh : dim[1]
    end

    def shave_thumbnail( width, height, width0, height0)
      advice = @@advices[@source]
      if ((width0 * 1.0) / height0) > ((width * 1.0) / height)
        w = (height0 * (width * 1.0) / height).to_i
        x = (width0 - w) / 2
        x = 0 if advice == 'left'
        x = (width0 - w) if advice == 'right'
        return w, height0, x, 0
      else
        h = (width0 * (height * 1.0) / width).to_i
        y = (height0 - h) / 2
        y = 0 if advice == 'top'
        y = height0 - h if advice == 'bottom'
        return width0, h, 0, y
      end
    end

    def to_data( compiler, article)
      if error?
        return {'type' => 'none'}
      end
      dims = get_scaled_dims( compiler.dimensions( 'image'), [self])
      {'type'    => 'image',
       'clazz'   => 'centre',
       'overlay' => false,
       'id'      => anchor,
       'details' => details( compiler, article, dims,:prepare_source_image)
       }
    end
  end
end