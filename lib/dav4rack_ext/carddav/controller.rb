module DAV4Rack
  module Carddav
    
    class Controller < DAV4Rack::Controller
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
end
