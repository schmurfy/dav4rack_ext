module DAV4Rack
  module Carddav
    
    class PrincipalResource < Resource
      
      def exist?
        ret = (path == '') || (path == '/')
        return ret
      end

      def collection?
        return true
      end
      
      
      define_properties('DAV:') do
        property('alternate-URI-set') do
          # "<D:alternate-URI-set xmlns:D='DAV:' />"
        end
        
        property('group-membership') do
          # "<D:group-membership xmlns:D='DAV:' />"
        end
        
        property('group-membership-set') do
          # "<D:group-membership-set xmlns:D='DAV:' />"
        end
        
        property('principal-URL') do
          <<-EOS
            <D:principal-URL xmlns:D='DAV:'>
              <D:href>#{options[:root_uri_path]}</D:href>
            </D:principal-URL>
          EOS
        end
        
        # This violates the spec that requires an HTTP or HTTPS URL.  Unfortunately,
        # Apple's AddressBook.app treats everything as a pathname.  Also, the model
        # shouldn't need to know about the URL scheme and such.
        property('current-user-principal') do
          <<-EOS
            <D:current-user-principal xmlns:D='DAV:'>
              <D:href>#{options[:root_uri_path]}</D:href>
            </D:current-user-principal>
          EOS
        end
        
        property('acl') do
          <<-EOS
            <D:acl xmlns:D='DAV:'>
              <D:ace>
                <D:principal>
                  <D:href>#{options[:root_uri_path]}</D:href>
                </D:principal>
                <D:protected/>
                <D:grant>
                  #{get_privileges_aggregate}
                </D:grant>
              </D:ace>
            </D:acl>
          EOS
        end
        
        property('acl-restrictions') do
          <<-EOS
            <D:acl-restrictions xmlns:D='DAV:'>
              <D:grant-only/><D:no-invert/>
            </D:acl-restrictions>
          EOS
        end

        
        property('resourcetype') do
          <<-EOS
            <resourcetype>
              <D:collection />
              <D:principal />
            </resourcetype>
          EOS
        end
        
        property('displayname') do
          "User Principal Resource"
        end
        
        property('creationdate') do
          current_user.created_at
        end
        
        property('getlastmodified') do
          current_user.updated_at
        end
      end
      
      define_properties(CARDAV_NS) do
        explicit do
          property('addressbook-home-set') do
            <<-EOS
              <C:addressbook-home-set xmlns:C='#{CARDAV_NS}'>
                <D:href xmlns:D='DAV:'>#{options[:books_collection]}</D:href>
              </C:addressbook-home-set>
            EOS
          end
          
          # TODO: should return the user's card url
          # (ex: /users/schmurfy.vcf ) (RFC 7.1.2)
          property('principal-address') do
            ""
          end

        end
      end

    end
  end
end
