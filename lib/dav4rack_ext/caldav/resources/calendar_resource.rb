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
          @calendar.description
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

          property('supported-calendar-component-set') do
            <<-EOS
              <C:supported-calendar-component-set xmlns:C='#{CALDAV_NS}'>
                <C:comp name="VEVENT"/>
              </C:supported-calendar-component-set>
            EOS
          end

          property('supported-calendar-data') do
            <<-EOS
              <C:supported-calendar-data xmlns:C='#{CALDAV_NS}'>
                <C:calendar-data-type content-type='text/calendar' version='2.0' />
              </C:supported-calendar-data>
            EOS
          end

          property('calendar-description') do
            @calendar.description
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
        @skip_alias << :find_calendar # jesus christ superstart... wtf d4r?
        @calendar = @options[:_object_] || find_calendar(router_params[:calendar_id]) || find_calendar(request.env['action_dispatch.request.path_parameters'][:calendar_id])
      end

      def exist?
        @calendar != nil
      end

      def collection?
        true
      end

      def find_calendar(calendar_id)
        current_user.calendars.find do |calendar|
          calendar.path == calendar_id
        end
      end

      def find_event(event_id)
        if @calendar.events.is_a? Array
          @calendar.events.find { |e| e.path == event_id }
        else
          @calendar.events.find event_id
        end
      end

      def children
        @calendar.events.collect do |event|
          child(EventResource, event, @calendar)
        end
      end

      def find_child(uid)
        uid = File.basename(uid, '.ics')
        event = find_event(uid)
        if event
          child(EventResource, event)
        else
          nil
        end
      end

    end
  end
end
