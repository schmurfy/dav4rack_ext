module DAV4Rack
  module Carddav

    class PrincipalResource < Resource

      def exist?
        (path == '') || (path == '/')
      end

      def collection?
        true
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
              <D:href>#{root_uri_path}</D:href>
            </D:principal-URL>
          EOS
        end

        property('current-user-principal') do
          <<-EOS
            <D:current-user-principal xmlns:D='DAV:'>
              <D:href>#{root_uri_path}</D:href>
            </D:current-user-principal>
          EOS
        end

        property('acl') do
          <<-EOS
            <D:acl xmlns:D='DAV:'>
              <D:ace>
                <D:principal>
                  <D:href>#{root_uri_path}</D:href>
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
                <D:href xmlns:D='DAV:'>#{books_collection_url}</D:href>
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

    private

      def books_collection_url
        File.join(root_uri_path, options[:books_collection])
      end

    end
  end
end
