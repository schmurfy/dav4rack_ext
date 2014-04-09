module DAV4Rack
  module Caldav
    # TODO: 1:1 copy of Carddav Resource, needs refactoring
    class Resource < DAV4Rack::Resource
      extend Helpers::Properties

      CALDAV_NS = 'urn:ietf:params:xml:ns:caldav'.freeze

      PRIVILEGES = %w(read read-acl read-current-user-privilege-set)

      def initialize(*)
        super
        raise ArgumentError, "missing current_user lambda" unless options[:current_user]
      end

      def current_user
        @current_user ||= options[:current_user].call(env)
      end

      def user_agent
        options[:env]['HTTP_USER_AGENT'].to_s rescue ""
      end

      def router_params
        env['router.params'] || {}
      end

      def setup
        @propstat_relative_path = true
        @root_xml_attributes = {
          'xmlns:C' => CALDAV_NS,
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

        if handler = self.class.properties[key]
          ret = instance_exec(element, &handler[0])
          # TODO: find better than that
          if ret.is_a?(String) && ret.include?('<')
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
              <D:href>#{root_uri_path}</D:href>
            </D:owner>
          EOS
        end

      end

      def properties
        selected_properties = self.class.properties.reject{|key, arr| arr[1] == true }
        selected_properties.keys.map do |key|
          ns, name = key.split('*')
          {:name => name, :ns_href => ns}
        end
      end

      def children
        []
      end


    private
      def env
        options[:env] || {}
      end

      def root_uri_path
        tmp = @options[:root_uri_path]
        tmp.respond_to?(:call) ? tmp.call(env) : tmp
      end

      def get_privileges_aggregate
        privileges_aggregate = PRIVILEGES.inject('') do |ret, priv|
          ret << '<D:privilege><%s /></privilege>' % priv
        end
      end

      def add_slashes(str)
        "/#{str}/".squeeze('/')
      end

      def child(child_class, child, parent = nil)
        new_public = add_slashes(public_path)
        new_path = add_slashes(path)

        child_class.new("#{new_public}#{child.path}", "#{new_path}#{child.path}",
            request, response, options.merge(_object_: child, _parent_: self)
          )
      end

    end

  end
end
