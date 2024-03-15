require_relative '../utils'

module Elements
  class Tag < Element
    include Utils
    @@locations = Hash.new {|h,k| h[k] = []}
    attr_reader :article, :location, :origin

    def initialize( compiler, article, defn)
      @article   = article
      @location  = defn[0]
      @rendered  = 0
      @origin    = @location.gsub( /\W/, '_').gsub( /_+/, '_').downcase
      if SPECIAL_CHARS =~ @location
        article.error( 'Bad characters in tag')
        @discard = true
      else
        @@locations[@location] << self
      end
    end

    def self.check_all_rendered
      @@locations.each_value do |elements|
        elements.each do |element|
          element.check_rendered
        end
      end
    end

    def check_rendered
      if @rendered == 0
        @article.error( "Location #{@location} not rendered")
      elsif @rendered > 1
        @article.error( "Location #{@location} multiply rendered")
      end
    end

    def date
      @article.date
    end

    def filename
      super + (@origin ? "?origin=#{@origin}" : '')
    end

    def self.find( name)
      @@locations[name]
    end

    def icon
      @article.icon
    end

    def method_missing( name, *args, &block)
      @article.send( name, *args, &block)
    end

    def multiline?
      false
    end

    def page_content?
      false
    end

    def publish?
      return true unless date
      date <= Time.now
    end

    def render
      @rendered += 1
    end

    def set_origin( parents)
      if @origin == 'default'
        @article.error( 'Tag name default not allowed')
      end
      @article.origin( @origin, parents)
    end
  end
end