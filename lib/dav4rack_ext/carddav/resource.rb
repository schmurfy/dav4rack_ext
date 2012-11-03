module DAV4Rack
  module Carddav
    
    class Resource < DAV4Rack::Resource
      extend Helpers::Properties

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
          <<-EOS
            <D:acl xmlns:D='DAV:'>
              <D:ace>
                <D:principal>
                  <D:href>#{options[:root]}</D:href>
                </D:principal>
                <D:protected/>
                <D:grant>
                  #{get_privileges_aggregate}
                </D:grant>
              </D:ace>
            </D:acl>"
          EOS
        end
        
        property('acl-restrictions') do
          <<-EOS
            <D:acl-restrictions xmlns:D='DAV:'>
              <D:grant-only/><D:no-invert/>
            </D:acl-restrictions>
          EOS
        end
        
        # This violates the spec that requires an HTTP or HTTPS URL.  Unfortunately,
        # Apple's AddressBook.app treats everything as a pathname.  Also, the model
        # shouldn't need to know about the URL scheme and such.
        property('current-user-principal') do
          <<-EOS
            <D:current-user-principal xmlns:D='DAV:'>
              <D:href>#{options[:root]}</D:href>
            </D:current-user-principal>
          EOS
        end
        
        property('current-user-privilege-set') do
          <<-EOS
            <D:current-user-privilege-set xmlns:D="DAV:">
              #{get_privileges_aggregate}
            </D:current-user-privilege-set>
          EOS
        end
        
        property('group') do
          ""
        end

        property('owner') do
          <<-EOS
            <D:owner xmlns:D='DAV:'>
              <D:href>#{options[:root]}</D:href>
            </D:owner>
          EOS
        end

        property('principal-URL') do
          <<-EOS
            <D:principal-URL xmlns:D='DAV:'>
              <D:href>#{options[:root]}</D:href>
            </D:principal-URL>
          EOS
        end
        
      end

      def properties
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
