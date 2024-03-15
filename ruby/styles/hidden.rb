require_relative 'base'

module Styles
  class Hidden < Base
    def index?
      false
    end

    def prepare( compiler, article, parents)
      unless parents.size == 1
        article.error( 'Hidden page must be at root of website')
      end
    end

    def post_process_html( root_url, article, html)
      html = super
      html = html.gsub( /href="[^"]*"/i) do |match|
        if /:/ =~ match
          match
        else
          match.sub('"','"' + root_url)
        end
      end
      html.gsub( 'url("./', 'url("' + root_url)
    end
  end
end
