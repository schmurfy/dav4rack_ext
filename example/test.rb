
require 'faraday'

c = Faraday.new(:url => 'http://127.0.0.1:3000/carddav') do |faraday|
  faraday.adapter  Faraday.default_adapter
  # faraday.response :logger                  # log requests to STDOUT
end

Faraday::Connection::METHODS << :propfind
Faraday::Connection::METHODS << :report


# response = c.run_request(:propfind, nil, <<-EOS, nil, &nil)
# <?xml version="1.0" encoding="UTF-8"?>
# <A:propfind xmlns:A="DAV:">
#   <A:prop>
#     <A:current-user-principal/>
#     <A:principal-URL/>
#     <A:resourcetype/>
#   </A:prop>
# </A:propfind>
# EOS

# response = c.run_request(:report, '/book/1', <<-EOS, nil)
# <?xml version="1.0" encoding="UTF-8"?>
# <G:addressbook-multiget xmlns:G="urn:ietf:params:xml:ns:carddav">
#   <A:prop xmlns:A="DAV:">
#     <A:getetag/>
#     <G:address-data/>
#   </A:prop>
#   <A:href xmlns:A="DAV:">/book/1/11</A:href>
# </G:addressbook-multiget>
# EOS


response = c.run_request(:propfind, nil, <<-EOS, nil)
<?xml version="1.0" encoding="UTF-8"?>
<A:propfind xmlns:A="DAV:">
  <A:prop>
    <B:addressbook-home-set xmlns:B="urn:ietf:params:xml:ns:carddav"/>
    <B:directory-gateway xmlns:B="urn:ietf:params:xml:ns:carddav"/>
    <A:displayname/>
    <C:email-address-set xmlns:C="http://calendarserver.org/ns/"/>
    <A:principal-collection-set/>
    <A:principal-URL/>
    <A:resource-id/>
    <A:supported-report-set/>
  </A:prop>
</A:propfind>
EOS
