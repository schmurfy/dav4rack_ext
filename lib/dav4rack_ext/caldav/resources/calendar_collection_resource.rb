module DAV4Rack
  module Caldav
    class CalendarCollectionResource < Resource

      def exist?
        true
      end

      def collection?
        true
      end

      def children
        current_user.calendars.map do |calendar|
          child(CalendarResource, calendar)
        end
      end

    end
  end
end
