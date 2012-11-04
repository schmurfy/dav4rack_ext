module DAV4Rack
  module Carddav
    
    class AddressbookResource < AddressbookBaseResource
      
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
          reports = %w(addressbook-multiget)
          s = "<supported-report-set>%s</supported-report-set>"
          
          reports_aggregate = reports.inject('') do |ret, report|
            ret << "<report><C:%s xmlns:C='urn:ietf:params:xml:ns:carddav'/></report>" % report
          end
          
          s % reports_aggregate
        end
        
        property('resourcetype') do
          <<-EOS
            <resourcetype>
              <D:collection />
              <C:addressbook xmlns:C="urn:ietf:params:xml:ns:carddav"/>
            </resourcetype>
          EOS
        end
        
        property('displayname') do
          @address_book.name
        end
        
        property('creationdate') do
          @address_book.created_at
        end
        
        property('getcontenttype') do
          <<-EOS
            <getcontenttype>httpd/unix-directory</getcontenttype>
          EOS
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
          
          # TODO: fill this
          property('supported-collation-set') do
            
          end
          
        end
        
      end
      
      
      define_properties('http://calendarserver.org/ns/') do
        property('getctag') do
          <<-EOS
            <APPLE1:getctag xmlns:APPLE1='http://calendarserver.org/ns/'>
              #{@address_book.updated_at.to_i}
            </APPLE1:getctag>
          EOS
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
          child(c.uid.to_s)
        end
      end
      
      def child(name)
        super(ContactResource, name)
      end
      
    end
    
  end
end
