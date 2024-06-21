require_relative 'image'

module Elements
  class Heading < Element
    include Utils

    def initialize( compiler, article, text)
      super( article)
      @text = check_label( article, text[0])
    end

    def multiline?
      false
    end

    def to_data( compiler, article)
      {'type'  => 'heading',
       'text'  => @text}
    end
  end
 end