require_relative '../../../spec_helper'

describe 'Addressbooks Collection' do
  
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    @books = [
      FactoryGirl.build(:book, path: 'first'),
      FactoryGirl.build(:book, path: 'second')
    ]
    
    @user_builder = proc do |env|
      FactoryGirl.build(:user, env: env, login: 'john', addressbooks: @books)
    end
    
  end
  
  
  describe 'HTTP' do
    before do
      user_builder = @user_builder
      app = Rack::Builder.new do
        # use XMLSniffer
        run DAV4Rack::Carddav.app('/', current_user: user_builder)
      end
      
      serve_app(app)
    end
    
    should 'return correct path on PROPFIND' do
      response = propfind('/books/', [
          ['displayname', @dav_ns]
        ])
      
      ensure_element_exists(response, %{D|response > D|href[text()="/books/first/"]})
      ensure_element_exists(response, %{D|response > D|href[text()="/books/second/"]})
    end
    
    
    should 'respond correctly on PROPFIND without body' do
      response = request(:propfind, '/books/')
      
      ensure_element_exists(response, %{D|href[text()="/books/first/"] + D|propstat > D|prop > D|getcontenttype[text()="httpd/unix-directory"]})
      ensure_element_exists(response, %{D|href[text()="/books/second/"] + D|propstat > D|prop > D|getcontenttype[text()="httpd/unix-directory"]})
    end
    
  end
  
end
