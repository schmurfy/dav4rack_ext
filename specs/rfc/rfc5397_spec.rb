require File.expand_path('../../spec_helper', __FILE__)

describe 'RFC 5397: WebDAV Current Principal Extension' do
  before do
    @dav_ns = "DAV:"
    
    @user = user = stub('User', username: 'john')
    
    @root_path = root_path = '/'
    
    app = Rack::Builder.new do
      use XMLSniffer
      run DAV4Rack::Carddav.app(root_path, current_user: user)
    end
    
    serve_app(app)
  end
  
  describe '[3] DAV:current-user-principal' do
    should 'return current user principal' do
      response = propfind(@root_path, [
          ['current-user-principal', @dav_ns]
        ])
      
      ensure_element_exists(response, %{D|prop > D|current-user-principal > D|href[text()="#{@root_path}"]})
    end
    
    should 'return unauthenticated if not logged in' do
      # response = propfind(@root_path, [
      #     ['current-user-principal', @dav_ns]
      #   ])
      
      # ensure_element_exists(response, %{D|prop > D|current-user-principal > D|unauthenticated})
    end
    
  end
  
end
