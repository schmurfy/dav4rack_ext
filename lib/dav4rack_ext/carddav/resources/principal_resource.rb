module DAV4Rack
  module Carddav
    
    class PrincipalResource < Resource

      def exist?
        ret = (path == '') || (path == '/')
        STDERR.puts "*** Principal::exist?(#{path}) = #{ret}"
        return ret
      end

      def collection?
        return true
      end
      
      def children
        []
      end
      
      
      define_properties('DAV:') do
        property('alternate-URI-set') do
          "<D:alternate-URI-set xmlns:D='DAV:' />"
        end
        
        property('group-membership') do
          "<D:group-membership xmlns:D='DAV:' />"
        end
        
        property('group-membership-set') do
          "<D:group-membership-set xmlns:D='DAV:' />"
        end
        
        property('resourcetype') do
          '<resourcetype><D:collection /><D:principal/></resourcetype>'
        end
        
        property('displayname') do
          "<D:displayname>#{current_user.username}'s Principal Resource</<D:displayname>"
        end
      end
      
      define_properties('urn:ietf:params:xml:ns:carddav') do
        explicit do
          property('addressbook-home-set') do
            "<C:addressbook-home-set xmlns:C='urn:ietf:params:xml:ns:carddav'><D:href xmlns:D='DAV:'>/book/</D:href></C:addressbook-home-set>"
          end
          
          # TODO: should return the user's card url
          # (ex: /users/schmurfy.vcf ) (RFC 7.1.2)
          property('principal-address') do
            ""
          end

        end
      end
      




      def creation_date
        # TODO: There's probably a more efficient way to grab the oldest ctime
        # Perhaps we should assume that the address book will never be newer than
        # any of its constituent contacts?
        # contact_ids = @addressbook_model_class.find_all_by_user_id(current_user.id).collect{|ab| ab.contacts.collect{|c| c.id}}.flatten
        # Field.first(:order => 'created_at ASC', :conditions => ['contact_id IN (?)', contact_ids]).created_at
        
        # TODO: change this
        Time.now
      end

      def last_modified
        # address_books = AddressBook.find_all_by_user_id(current_user.id)
        # contact_ids = address_books.collect{|ab| ab.contacts.collect{|c| c.id}}.flatten
        # field = Field.first(:order => 'updated_at DESC', :conditions => ['contact_id IN (?)', contact_ids])
        # return field.updated_at unless field.nil?
        # return address_books.first.updated_at unless address_books.nil?
        Time.now
      end

    end
  end
end
