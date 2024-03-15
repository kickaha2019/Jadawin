require_relative 'dated_events'

module Styles
  class ReverseDatedEvents < DatedEvents
    def sort( articles)
      super.reverse
    end
  end
end
