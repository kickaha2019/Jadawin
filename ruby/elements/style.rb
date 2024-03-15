require_relative 'image'

module Elements
  class Style < Element
    attr_reader :style

    def initialize( compiler, article, lines)
      begin
        path = lines[0].gsub( /[A-Z]/) {|letter| "_#{letter}"}
        path = path.downcase.gsub( /^_/, '')
        require_relative "../styles/#{path}"
        @style = Kernel.const_get( 'Styles::' + lines[0]).new
      rescue Exception => bang
        article.error( 'Unimplemented style: ' + lines[0])
        @discard = true
      end
    end

    def multiline?
      false
    end

    def page_content?
      false
    end

    def special?
      true
    end
  end
end