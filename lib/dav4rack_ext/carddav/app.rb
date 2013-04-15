require 'http_router'

module DAV4Rack
  module Carddav
    
    DAV_EXTENSIONS = ["access-control", "addressbook"].freeze
    
    def self.app(root_path = '/', opts = {})
      logger        = opts.delete(:logger) || ::Logger.new('/dev/null')
      current_user  = opts.delete(:current_user)
      root_uri_path = opts.delete(:root_uri_path) || root_path
      
      if (root_path != '/') && root_path[-1] == '/'
        root_path.slice!(-1..-1)
      end
      
      raise "unknown options: #{opts}" unless opts.empty?
      
      HttpRouter.new do |r|
        
        last_root_path_part = root_path.split('/').last
        
        # try to help iOS find its way
        r.add(%r{(?<root>.*/#{last_root_path_part})(?::[0-9]+)?/\.well(?:_|-)known/carddav/?}).to do |env|
                  
          headers = {
            'Location'  => env['router.params'][:root],
            'Content-Type' => 'text/html',
          }
          
          [301, headers, []]
        end

        r.add("#{root_path}/").to DAV4RackExt::Handler.new(
            :logger                    => logger,
            :dav_extensions            => DAV_EXTENSIONS,
            :always_include_dav_header => true,
            :pretty_xml                => true,
            :root_uri_path             => root_uri_path,
            :resource_class            => DAV4Rack::Carddav::PrincipalResource,
            :controller_class          => DAV4Rack::Carddav::Controller,
            :current_user              => current_user,
            
            # resource options
            :books_collection          => "/books/"
          )
        
        r.add("#{root_path}/books/").to DAV4RackExt::Handler.new(
            :logger                    => logger,
            :dav_extensions            => DAV_EXTENSIONS,
            :always_include_dav_header => true,
            :pretty_xml                => true,
            :root_uri_path             => root_uri_path,
            :resource_class            => DAV4Rack::Carddav::AddressbookCollectionResource,
            :controller_class          => DAV4Rack::Carddav::Controller,
            :current_user              => current_user
          )
        
        r.add("#{root_path}/books/:book_id/:contact_id(.vcf)").to DAV4RackExt::Handler.new(
            :logger                    => logger,
            :dav_extensions            => DAV_EXTENSIONS,
            :always_include_dav_header => true,
            :pretty_xml                => true,
            :root_uri_path             => root_uri_path,
            :resource_class            => DAV4Rack::Carddav::ContactResource,
            :controller_class          => DAV4Rack::Carddav::Controller,
            :current_user              => current_user
          )
        
        r.add("#{root_path}/books/:book_id").to DAV4RackExt::Handler.new(
            :logger                    => logger,
            :dav_extensions            => DAV_EXTENSIONS,
            :always_include_dav_header  => true,
            :pretty_xml                => true,
            :root_uri_path             => root_uri_path,
            :resource_class            => DAV4Rack::Carddav::AddressbookResource,
            :controller_class          => DAV4Rack::Carddav::Controller,
            :current_user              => current_user
          )
        
        # Another hack for iOS 6
        # 
        r.default ->(env){
          # iOS will consider the principal urls to be  relative to
          # the current path so it will request a path like this:
          # /tt/cards/tt/cards/
          # 
          # if we detect something like this we issue a redirect to
          # /tt/cards
          # 
          # after that iOS 6 seems to behave as expected.
          path = env['REQUEST_PATH'] || env['PATH_INFO']
          
          parts = path.split('/').reject(&:empty?)
          
          if parts.size % 2 == 0
            half1 = parts[0...parts.size / 2]
            half2 = parts[parts.size / 2..-1]
            
            if half1 == half2
              headers = {
                'Location'  => "/#{half1.join('/')}",
                'Content-Type' => 'text/html',
              }
              
              return [301, headers, []]
            end
          end
          
          
          [404, {}, []]
        }
      end
    end
    
  end
end
