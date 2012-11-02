require_relative '../../spec_helper'

describe 'Rack App' do
  before do
    @user = stub('User', username: 'john')
  end
  
  def app
    user = @user
    Rack::Builder.new do
      use XMLSniffer
      run DAV4Rack::Carddav.app(current_user: ->{ user })
    end
  end

  
  should 'works' do
    request('/carddav/', method: 'PROPFIND', input: <<-EOS)
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
    
    last_response.status.should == 207
  end
  
  
#   should 'works' do
#     c = Faraday.new(:url => 'http://127.0.0.1:11000/carddav') do |faraday|
#       faraday.adapter  Faraday.default_adapter
#       # faraday.response :logger                  # log requests to STDOUT
#     end

#     Faraday::Connection::METHODS << :propfind
#     Faraday::Connection::METHODS << :report

    
#     # ret = http_request(:options, '/carddav/', body: <<-EOS)
#     response = c.run_request(:propfind, nil, <<-EOS, nil)
# <?xml version="1.0" encoding="UTF-8"?>
# <A:propfind xmlns:A="DAV:">
#   <A:prop>
#     <B:addressbook-home-set xmlns:B="urn:ietf:params:xml:ns:carddav"/>
#     <B:directory-gateway xmlns:B="urn:ietf:params:xml:ns:carddav"/>
#     <A:displayname/>
#     <C:email-address-set xmlns:C="http://calendarserver.org/ns/"/>
#     <A:principal-collection-set/>
#     <A:principal-URL/>
#     <A:resource-id/>
#     <A:supported-report-set/>
#   </A:prop>
# </A:propfind>
#     EOS
    
#     p response.body
#     # check_http_response_status(ret, 200)
#   end
end
