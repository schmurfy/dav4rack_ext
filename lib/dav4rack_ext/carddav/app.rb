require 'http_router'

module DAV4Rack
  module Carddav
    
    DAV_EXTENSIONS = ["access-control", "addressbook"].freeze
    
    def self.app(root_path = '/', opts = {})
      logger = opts.delete(:logger) || ::Logger.new('/dev/null')
      current_user = opts.delete(:current_user)
      
      if root_path[-1] != '/'
        root_path << '/'
      end
      
      raise "unknown options: #{opts}" unless opts.empty?
      
      HttpRouter.new do |r|

        r.add("#{root_path}").to DAV4RackExt::Handler.new(
            :logger                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            # :root                     => root_path,
            :root_uri_path            => root_path,
            :resource_class           => DAV4Rack::Carddav::PrincipalResource,
            :controller_class         => DAV4Rack::Carddav::Controller,
            :current_user             => current_user,
            
            # resource options
            :books_collection         => "#{root_path}books/"
          )
        
        r.add("#{root_path}books/").to DAV4RackExt::Handler.new(
            :logger                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            # :root                     => '/book',
            # :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::AddressbookCollectionResource,
            :controller_class         => DAV4Rack::Carddav::Controller,
            :current_user             => current_user
          )
        
        r.add("#{root_path}books/:book_id/:contact_id(.vcf)").to DAV4RackExt::Handler.new(
            :logger                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            # :root                     => '/book',
            # :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::ContactResource,
            :controller_class         => DAV4Rack::Carddav::Controller,
            :current_user             => current_user
          )
        
        r.add("#{root_path}books/:book_id").to DAV4RackExt::Handler.new(
            :logger                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            # :root                     => '/book',
            # :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::AddressbookResource,
            :controller_class         => DAV4Rack::Carddav::Controller,
            :current_user             => current_user
          )
        
      end
    end
    
  end
end
