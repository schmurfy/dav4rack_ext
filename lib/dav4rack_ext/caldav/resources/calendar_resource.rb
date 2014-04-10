module DAV4Rack
  module Caldav
    class CalendarResource < Resource

      define_properties('DAV:') do
        property('current-user-privilege-set') do
          privileges = %w(read write write-properties write-content read-acl read-current-user-privilege-set)
          s='<D:current-user-privilege-set xmlns:D="DAV:">%s</D:current-user-privilege-set>'

          privileges_aggregate = privileges.inject('') do |ret, priv|
            ret << '<D:privilege><%s /></privilege>' % priv
          end

          s % privileges_aggregate
        end

        property('supported-report-set') do
          reports = %w(calendar-multiget)
          s = "<supported-report-set>%s</supported-report-set>"

          reports_aggregate = reports.inject('') do |ret, report|
            ret << "<report><C:%s xmlns:C='#{CALDAV_NS}'/></report>" % report
          end

          s % reports_aggregate
        end

        property('resourcetype') do
          <<-EOS
            <resourcetype>
              <D:collection />
              <C:calendar xmlns:C="#{CALDAV_NS}"/>
            </resourcetype>
          EOS
        end

        property('displayname') do
          @calendar.name
        end

        property('creationdate') do
          @calendar.created_at
        end

        property('getcontenttype') do
          "httpd/unix-directory"
        end

        # property('getetag') do
        #   '"None"'
        # end

        property('getlastmodified') do
          @calendar.updated_at
        end
      end


      define_properties(CALDAV_NS) do
        explicit do
          property('max-resource-size') do
            1024
          end

          property('supported-calendar-data') do
            <<-EOS
              <C:supported-calendar-data xmlns:C='#{CALDAV_NS}'>
                <C:calendar-data-type content-type='text/calendar' version='2.0' />
              </C:supported-calendar-data>
            EOS
          end

          property('calendar-description') do
            @calendar.name
          end

          property('max-resource-size') do

          end

          # TODO: fill this
          property('supported-collation-set') do

          end
        end

      end


      define_properties('http://calendarserver.org/ns/') do
        property('getctag') do
          <<-EOS
            <APPLE1:getctag xmlns:APPLE1='http://calendarserver.org/ns/'>
              #{@calendar.ctag}
            </APPLE1:getctag>
          EOS
        end
      end

      def setup
        super
        @calendar = @options[:_object_] || current_user.current_calendar
      end

      def exist?
        @calendar != nil
      end

      def collection?
        true
      end

      def children
        @calendar.events.collect do |event|
          child(EventResource, event, @calendar)
        end
      end

      def find_child(uid)
        uid = File.basename(uid, '.ics')
        event = @calendar.events.find_by(id: uid)
        if event
          child(EventResource, event)
        else
          nil
        end
      end

    end
  end
end
