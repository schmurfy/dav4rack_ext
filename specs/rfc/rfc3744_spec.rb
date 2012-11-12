require File.expand_path('../../spec_helper', __FILE__)

describe 'RFC 3744: WebDav Access Control Protocol' do
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
  
  describe '[4] Principal Properties' do
    it '[4.2] DAV:principal-URL' do
      response = propfind(@root_path, [
          ['principal-URL', @dav_ns]
        ])
      
      ensure_element_exists(response, %{D|prop > D|principal-URL > D|href[text()="#{@root_path}"]})
    end
  end
  
  describe '[5] Access Control Properties' do
    
    describe '[5.5] DAV::ACL Element' do
      it '[5.5.1] ACE Principal' do
        response = propfind(@root_path, [
            ['acl', @dav_ns]
          ])
        
        # check that there is one principal which is the root
        ensure_element_exists(response, %{D|prop > D|acl > D|ace D|principal D|href[text()="#{@root_path}"]})
      end
      
    end
    
    it '[5.1]  DAV:owner' do
      response = propfind(@root_path, [
          ['owner', @dav_ns]
        ])
      
      ensure_element_exists(response, %{D|prop > D|owner > D|href[text()="#{@root_path}"]})
    end
    
    it '5.2]  DAV:group' do
      response = propfind(@root_path, [
          ['group', @dav_ns]
        ])
      
      elements = ensure_element_exists(response, %{D|prop > D|group})
      elements[0].text.should == ""
    end
    
  end
  
end
