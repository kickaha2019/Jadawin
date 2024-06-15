require_relative 'events'

module Styles
  class DatedEvents < Events
    def index_title( page)
      if d = page.date
        super( page) + page.date.strftime( ' (%b %Y)')
      else
        page.error( 'Missing date for DatedEvents page')
        super( page)
      end
    end
  end
end
