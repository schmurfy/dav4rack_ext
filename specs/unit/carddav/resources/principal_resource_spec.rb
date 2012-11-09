require_relative '../../../spec_helper'

describe 'Principal Resource' do
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    user_builder = proc do |env|
      FactoryGirl.build(:user, env: env, login: 'john')
    end
        
    app = Rack::Builder.new do
      # use XMLSniffer
      run DAV4Rack::Carddav.app('/cards/', current_user: user_builder)
    end
    
    serve_app(app)
  end
  
  should 'return /cards/ as principal-URI' do
    headers = {
      'HTTP_USER_AGENT' => 'Anything'
    }
    
    response = propfind('/cards/', [
        ['principal-URL', @dav_ns]
      ], headers)
    
    ensure_element_exists(response, %{D|prop > D|principal-URL > D|href[text()="/cards/"]})
  end
  
  should 'return / as principal-URI for iOS 6.0' do
    headers = {
      'HTTP_USER_AGENT' => 'iOS/6.0 (10A403) Preferences/1.0'
    }
    
    response = propfind('/cards/', [
        ['principal-URL', @dav_ns]
      ], headers)
    
    ensure_element_exists(response, %{D|prop > D|principal-URL > D|href[text()="/"]})
  end
  
end
