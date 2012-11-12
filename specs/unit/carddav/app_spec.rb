require File.expand_path('../../../spec_helper', __FILE__)


describe 'Rack App' do
  before do
    @user = user = stub('User', username: 'john')
    
    app = Rack::Builder.new do
      use XMLSniffer
      run DAV4Rack::Carddav.app('/', current_user: user)
    end
    
    serve_app(app)
  end
  
  should 'works' do
    response = request(:propfind, '/', input: <<-EOS)
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
    
    response.status.should == 207
  end
  
end
