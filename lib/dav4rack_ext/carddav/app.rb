require 'http_router'

module DAV4Rack
  module Carddav
    
    DAV_EXTENSIONS = ["access-control", "addressbook"].freeze
    
    def self.app(opts = {})
      logger = opts.delete(:logger)
      current_user = opts.delete(:current_user)
      addressbook_model = opts.delete(:addressbook_model)
      contact_model = opts.delete(:contact_model)
      
      raise "unknown options" unless opts.empty?
      
      HttpRouter.new do |r|

        r.add('/carddav/').to DAV4Rack::Handler.new(
            :log_to                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            :root                     => '/carddav',
            :root_uri_path            => '/carddav',
            :resource_class           => DAV4Rack::Carddav::PrincipalResource,
            :current_user             => current_user
          )
        
        r.add('/book/:book_id/:contact_id(.vcf)').to DAV4Rack::Handler.new(
            :log_to                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            :root                     => '/book',
            :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::ContactResource,
            :addresbook_model         => addressbook_model,
            :contact_model            => contact_model,
            :current_user             => current_user
          )
        
        r.add('/book/:book_id').to DAV4Rack::Handler.new(
            :log_to                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            :root                     => '/book',
            :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::AddressbookResource,
            :controller_class         => DAV4Rack::Carddav::Controller,
            :addresbook_model         => addressbook_model,
            :contact_model            => contact_model,
            :current_user             => current_user
          )
        
        r.add('/book/').to DAV4Rack::Handler.new(
            :log_to                   => logger,
            :dav_extensions           => DAV_EXTENSIONS,
            :alway_include_dav_header => true,
            :pretty_xml               => true,
            :root                     => '/book',
            :root_uri_path            => '/book',
            :resource_class           => DAV4Rack::Carddav::AddressbookCollectionResource,
            :addresbook_model         => addressbook_model,
            :contact_model            => contact_model,
            :current_user             => current_user
          )
      end
    end
    
  end
end
