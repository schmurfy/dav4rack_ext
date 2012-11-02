module DAV4Rack
  module Carddav
    
    class AddressbookResource < AddressbookBaseResource

      # The CardDAV spec requires that certain resources not be returned for an
      # allprop request.  It's nice to keep a list of all the properties we support
      # in the first place, so let's keep a separate list of the ones that need to
      # be explicitly requested.
      # ALL_PROPERTIES =  {
      #   'DAV:' => %w(
      #     current-user-privilege-set
      #     supported-report-set
      #   ),
      #   "urn:ietf:params:xml:ns:carddav" => %w(
      #     max-resource-size
      #     supported-address-data
      #   ),
      #   'http://calendarserver.org/ns/' => %w( getctag )
      # }

      # EXPLICIT_PROPERTIES = {
      #   'urn:ietf:params:xml:ns:carddav' => %w(
      #     addressbook-description
      #     max-resource-size
      #     supported-collation-set
      #     supported-address-data
      #   )
      # }
      
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
          reports = %w(addressbook-multiget addressbook-query)
          s = "<D:supported-report-set>%s</D:supported-report-set>"
          
          reports_aggregate = reports.inject('') do |ret, report|
            ret << "<D:report><C:%s xmlns:C='urn:ietf:params:xml:ns:carddav'/></D:report>" % report
          end
          
          s % reports_aggregate
        end
        
        property('resourcetype') do
          '<resourcetype><D:collection /><C:addressbook xmlns:C="urn:ietf:params:xml:ns:carddav"/></resourcetype>'
        end
        
        property('displayname') do
          @address_book.name
        end
        
        property('creationdate') do
          @address_book.created_at
        end

        # property('getetag') do
        #   '"None"'
        # end

        property('getlastmodified') do
          @address_book.updated_at
        end
        
      end
      
      
      define_properties('urn:ietf:params:xml:ns:carddav') do
        explicit do
          property('max-resource-size') do
            1024
          end
          
          property('supported-address-data') do
            <<-EOS
            <C:supported-address-data xmlns:C='urn:ietf:params:xml:ns:carddav'>
              <C:address-data-type content-type='text/vcard' version='3.0' />
            </C:supported-address-data>
            EOS
          end

          property('addressbook-description') do
            @address_book.name
          end
          
          property('max-resource-size') do
            
          end
          
          property('supported-collation-set') do
            
          end
          
          property('supported-address-data') do
            
          end
        end
        
      end
      
      
      define_properties('http://calendarserver.org/ns/') do
        property('getctag') do
          "<APPLE1:getctag xmlns:APPLE1='http://calendarserver.org/ns/'>#{@address_book.updated_at.to_i}</APPLE1:getctag>"
        end
      end

      def setup
        super
        @address_book = current_user.find_addressbook(@book_path)
        # @address_book = @addressbook_model_class.find_by_id_and_user_id(@book_path, current_user.id)
      end

      def exist?
        # Rails.logger.error "ABR::exist?(#{public_path})"
        return !@address_book.nil?
      end

      def collection?
        true
      end

      def children
        Logger.debug "ABR::children(#{public_path})"
        @address_book.contacts.collect do |c|
          Logger.debug "Trying to create this child (contact): #{c.uid.to_s}"
          child c.uid.to_s
        end
      end
      
      
      def report(controller, request_document, response)
        unless exist?
          return NotFound
        end

        if request_document.nil? or request_document.root.nil?
          render_xml(:error) do |xml|
            xml.send :'empty-request'
          end
          raise BadRequest
        end

        case request_document.root.name
        when 'addressbook-multiget'
          addressbook_multiget(controller, request_document)
        else
          render_xml(:error) do |xml|
            xml.send :'supported-report'
          end
          raise Forbidden
        end
      end
      
      
      ## Properties follow in alphabetical order
      protected

      def content_type
        # Not the right type, oh well
        Mime::Type.lookup_by_extension(:dir).to_s
      end

      
    private
      include DAV4Rack::Utils
      
      def xpath_element(name, ns_uri=:dav)
        case ns_uri
        when :dav
          ns_uri = 'DAV:'
        when :carddav
          ns_uri = 'urn:ietf:params:xml:ns:carddav'
        end
        "*[local-name()='#{name}' and namespace-uri()='#{ns_uri}']"
      end
      
      def addressbook_multiget(ctrl, request_document)
        depth = ctrl.send(:depth)
        
        # TODO: Include a DAV:error response
        # CardDAV §8.7 clearly states Depth must equal zero for this report
        # But Apple's AddressBook.app sets the depth to infinity anyhow.
        unless depth == 0 or depth == :infinity
          render_xml(:error) do |xml|
            xml.send :'invalid-depth'
          end
          raise BadRequest
        end

        props = request_document.xpath("/#{xpath_element('addressbook-multiget', :carddav)}/#{xpath_element('prop')}").children.find_all(&:element?).map{|n|
          to_element_hash(n)
        }
        # Handle the address-data element
        # - Check for child properties (vCard fields)
        # - Check for mime-type and version.  If present they must match vCard 3.0 for now since we don't support anything else.
        hrefs = request_document.xpath("/#{xpath_element('addressbook-multiget', :carddav)}/#{xpath_element('href')}").collect{|n| 
          text = n.text
          # TODO: Make sure that the hrefs passed into the report are either paths or fully qualified URLs with the right host+protocol+port prefix
          path = URI.parse(text).path
          Logger.debug "Scanned this HREF: #{text} PATH: #{path}"
          text
        }.compact
        
        if hrefs.empty?
          xml_error(BadRequest) do |err|
            err.send :'href-missing'
          end
        end

        ctrl.send(:multistatus) do |xml|
          hrefs.each do |_href|
            xml.response do
              xml.href _href

              path = File.split(URI.parse(_href).path).last
              Logger.debug "Creating child w/ ORIG=#{public_path} HREF=#{_href} FILE=#{path}!"

              # TODO: Write a test to cover asking for a report expecting contact objects but given an address book path
              # Yes, CardDAVMate does this.
              cur_resource = is_self?(_href) ? self : child(File.split(path).last)
              
              if cur_resource.exist?
                ctrl.send(:propstats, xml, ctrl.send(:get_properties, cur_resource, props))
              else
                xml.status "#{http_version} #{NotFound.status_line}"
              end

            end
          end
        end
      end

    end
    
  end
end
