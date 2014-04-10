require 'vcard_parser'

module DAV4Rack
  module Caldav

    class EventResource < Resource

      define_properties('DAV:') do
        property('getetag') do
          %("#{@event.etag}")
        end

        property('creationdate') do
          @event.created_at
        end

        property('getcontentlength') do
          @event.to_ical.to_s.bytesize.to_s
        end

        property('getcontenttype') do
          "text/calendar"
        end

        property('getlastmodified') do
          @event.updated_at
        end
      end

      define_properties(CALDAV_NS) do
        explicit do
          property('calendar-data') do |el|

            #fields = el[:children].select{|e| e[:name] == 'prop' }.map{|e| e[:attributes]['name'] }
            data = @event.to_ical

            <<-EOS
            <C:calendar-data xmlns:C="#{CALDAV_NS}">
              <![CDATA[#{data}]]>
            </C:calendar-data>
            EOS
          end
        end
      end

      def collection?
        false
      end

      def exist?
        Logger.info "ContactR::exist?(#{public_path});"
        @event != nil
      end

      def setup
        super
        @calendar = @options[:_parent_] || current_user.current_calendar()
        @event = @options[:_object_] || current_user.current_event()
      end

      def put(request, response)
        b = request.body.read

        # Ensure we only have one vcard per request
        # Section 5.1:
        # Address object resources contained in address book collections MUST
        # contain a single vCard component only.
        vcards = VCardParser::VCard.parse(b)
        raise BadRequest if vcards.size != 1
        vcf = vcards[0]

        uid = vcf['UID'].value

        # [6.3.2] Check for If-None-Match: *
        # If set, client does want to create a new contact only, raise an error
        # if contact already exists
        want_new_contact = (request.env['HTTP_IF_NONE_MATCH'] == '*')

        @event = @calendar.find_event(uid)

        # If the client has explicitly stated they want a new contact
        raise Conflict if (want_new_contact and @event)

        if if_match = request.env['HTTP_IF_MATCH']
          # client wants to update a contact, return an error if no
          # contact was found
          if (if_match == '*') || !@event
            raise PreconditionFailed unless @event

          # client wants to update the contact with specific etag,
          # return an error if the contact was updated by someone else
          elsif (if_match != %("#{@event.etag}"))
            raise PreconditionFailed

          end
        end

        if @event
          Logger.debug("Updating contact #{uid} (#{@event.object_id})")
        else
          Logger.debug("Creating new contact ! (#{uid})")
          @event = @calendar.create_event(uid)
        end

        @event.update_from_ics(ics)

        if @contact.save(user_agent)
          new_public = @public_path.split('/')[0...-1]
          new_public << @event.uid.to_s

          @public_path = new_public.join('/')
          response['ETag'] = %("#{@event.etag}")
        end

        Created
      end

      def parent
        @calendar
      end

      def parent_exists?
        @calendar != nil
      end

      def parent_collection?
        true
      end

      def get(request, response)
        response.headers['Etag'] = %("#{@event.etag}")
        response.body = @event.to_ical
      end

      def delete
        @event.destroy
        NoContent
      end

    end

  end
end
