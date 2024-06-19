require_relative '../link'

module Styles
  class TextIndex < Events
    def render( compiler, parents, article, data)
      data['index_style']     = 'document' if article.has_any_content?
      data['text_index']      = article.text_index( parents[-1].children)
    end
  end
end
