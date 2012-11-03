module DAV4Rack
  module Carddav
    
    class Resource < DAV4Rack::Resource
      class MethodMissingRedirector
        def initialize(*methods, &block)
          @block = block
          @methods = methods
        end
        
        def method_missing(name, *args, &block)
          if @methods.empty? || @methods.include?(name)
            @block.call(name, *args, &block)
          end
        end
      end
      
      # inheritable accessor
      class <<self
        def define_property(namespace, name, explicit = false, &block)
          _properties["#{namespace}*#{name}"] = [block, explicit]
        end
        
        def properties
          inherited = superclass.respond_to?(:properties) ? superclass.properties : {}
          inherited.merge(_properties)
        end
        
        def _properties
          @properties ||= {}
        end
      end
      
      def self.define_properties(namespace, &block)
        explicit = false
        obj = MethodMissingRedirector.new(:property, :explicit) do |method_name, name, &block|
          if method_name == :property
            define_property(namespace, name.to_s, explicit, &block)
          elsif method_name == :explicit
            explicit = true
            block.call
          else
            raise NoMethodError, method_name
          end
        end
        
        obj.instance_eval(&block)
      end
      

      PRIVILEGES = %w(read read-acl read-current-user-privilege-set)
      
      def initialize(*)
        super
        raise ArgumentError, "missing current_user lambda" unless options[:current_user]
      end
      
      def current_user
        @current_user ||= (
            options[:current_user].respond_to?(:call) ? options[:current_user].call() : options[:current_user]
          )
      end
      
      # Make OSX's AddressBook.app happy :(
      def setup
        @propstat_relative_path = true
        @root_xml_attributes = {
          'xmlns:C' => 'urn:ietf:params:xml:ns:carddav', 
          'xmlns:APPLE1' => 'http://calendarserver.org/ns/'
        }
      end

      def is_self?(other_path)
        ary = [@public_path]
        ary.push(@public_path+'/') if @public_path[-1] != '/'
        ary.push(@public_path[0..-2]) if @public_path[-1] == '/'
        ary.include? other_path
      end
      
      # BASE_PROPERTIES = {
      #   'DAV:' => %w(
      #     acl
      #     acl-restrictions
      #     creationdate
      #     current-user-principal
      #     current-user-privilege-set
      #     displayname
      #     getcontentlength
      #     getcontenttype
      #     getetag
      #     getlastmodified
      #     group
      #     owner
      #     principal-URL
      #     resourcetype
      #   ),
      #   # Define this here as an empty array so it will fall through to dav4rack
      #   # and they'll return a NotImplemented instead of BadRequest
      #   'urn:ietf:params:xml:ns:carddav' => []
      # }

      def get_property(element)
        name = element[:name]
        namespace = element[:ns_href]
        
        key = "#{namespace}*#{name}"
        
        handler = self.class.properties[key]
        if handler
          ret = instance_eval(&handler[0])
          # TODO: find better than that
          if ret && ret.include?('<')
            Nokogiri::XML::DocumentFragment.parse(ret)
          else
            ret
          end
        else
          Logger.debug("[#{self.class.name}] no handler for #{namespace}:#{name}")
          super
        end
      end
      
      define_properties('DAV:') do
        
        property(:acl) do
          s="
          <D:acl xmlns:D='DAV:'>
            <D:ace>
              <D:principal>
                <D:href>/carddav/</D:href>
              </D:principal>
              <D:protected/>
              <D:grant>
              %s
              </D:grant>
            </D:ace>
          </D:acl>"
          s %= get_privileges_aggregate
        end
        
        property('acl-restrictions') do
          "<D:acl-restrictions xmlns:D='DAV:'><D:grant-only/><D:no-invert/></D:acl-restrictions>"
        end
        
        # This violates the spec that requires an HTTP or HTTPS URL.  Unfortunately,
        # Apple's AddressBook.app treats everything as a pathname.  Also, the model
        # shouldn't need to know about the URL scheme and such.
        property('current-user-principal') do
          "<D:current-user-principal xmlns:D='DAV:'><D:href>/carddav/</D:href></D:current-user-principal>"
        end
        
        property('current-user-privilege-set') do
          s = '<D:current-user-privilege-set xmlns:D="DAV:">%s</D:current-user-privilege-set>'
          s %= get_privileges_aggregate
        end
        
        property('group') do
          ""
        end

        property('owner') do
          "<D:owner xmlns:D='DAV:'><D:href>/carddav/</D:href></D:owner>"
        end

        property('principal-URL') do
          "<D:principal-URL xmlns:D='DAV:'><D:href>/carddav/</D:href></D:principal-URL>"
        end
        
      end

      # Some properties shouldn't be included in an allprop request
      # but it's nice to do some sanity checking so keeping a list is good
      def properties
        # TODO: test this
        selected_properties = self.class.properties.reject{|key, arr| arr[1] == true }
        ret = {}
        selected_properties.keys.map do |key|
          ns, name = key.split('*')
          {:name => name, :ns_href => ns}
        end
      end
      
      def children
        []
      end


      private
      def get_privileges_aggregate
        privileges_aggregate = PRIVILEGES.inject('') do |ret, priv|
          ret << '<D:privilege><%s /></privilege>' % priv
        end
      end

    end
    
  end
end
