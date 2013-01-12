module DAV4Rack
  module Carddav
    
    class Controller < DAV4Rack::Controller
      include DAV4Rack::Utils

      NAMESPACES = {
        'D' => 'DAV:',
        'C' => 'urn:ietf:params:xml:ns:carddav'
      }

      def initialize(*args, options, env)
        super(*args, options.merge(env: env))
      end
      
      def report
        unless resource.exist?
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
          addressbook_multiget(request_document)
        else
          render_xml(:error) do |xml|
            xml.send :'supported-report'
          end
          raise Forbidden
        end
      end
      
      
    private
      
      def root_uri_path
        tmp = @options[:root_uri_path]
        tmp.respond_to?(:call) ? tmp.call(@options[:env]) : tmp
      end
      
      def xpath_element(name, ns_uri=:dav)
        case ns_uri
        when :dav
          ns_uri = 'DAV:'
        when :carddav
          ns_uri = 'urn:ietf:params:xml:ns:carddav'
        end
        "*[local-name()='#{name}' and namespace-uri()='#{ns_uri}']"
      end

      def addressbook_multiget(request_document)
        # TODO: Include a DAV:error response
        # CardDAV §8.7 clearly states Depth must equal zero for this report
        # But Apple's AddressBook.app sets the depth to infinity anyhow.
        unless depth == 0 or depth == :infinity
          render_xml(:error) do |xml|
            xml.send :'invalid-depth'
          end
          raise BadRequest
        end

        # props = request_document.css("C|addressbook-multiget C|address-data > C|prop", namespaces).map do |el|
        props = request_document.css("C|addressbook-multiget C|address-data", NAMESPACES).map do |el|
          to_element_hash(el)
        end

        # collect the requested urls
        hrefs = request_document.css("C|addressbook-multiget D|href", NAMESPACES).map(&:content)

        multistatus do |xml|
          hrefs.each do |_href|
            xml.response do
              xml.href _href

              path = File.split(URI.parse(_href).path).last
              Logger.debug "Creating child w/ ORIG=#{resource.public_path} HREF=#{_href} FILE=#{path}!"

              cur_resource = resource.is_self?(_href) ? resource : resource.find_child(File.split(path).last)

              if cur_resource && cur_resource.exist?
                propstats(xml, get_properties(cur_resource, props))
              else
                xml.status "#{http_version} #{NotFound.status_line}"
              end

            end
          end
        end
      
    end
    
  end
end
