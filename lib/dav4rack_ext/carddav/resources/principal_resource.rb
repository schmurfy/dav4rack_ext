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
        
        property('creationdate') do
          current_user.created_at
        end
        
        property('getlastmodified') do
          current_user.updated_at
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

    end
  end
end
