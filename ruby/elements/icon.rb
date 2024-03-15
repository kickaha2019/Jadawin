require_relative 'image'

module Elements
  class Icon < Image
    def page_content?
      false
    end

    def prepare( compiler, article, parents, younger)
      icon = article.icon

      if icon != self
        if icon.instance_of?( Icon)
          article.error( 'Multiple icons')
        else
          article.error( 'Icon must be first image in article')
        end
      end
    end
  end
end