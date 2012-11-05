require_relative '../../../spec_helper'

describe 'Addressbooks Collection' do
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    @user = FactoryGirl.build(:user, login: 'john')
    
    
    @req = Rack::Request.new({})
    @response = stub('Response')
    
    @res = DAV4Rack::Carddav::AddressbookCollectionResource.new(
        "/books/", "/", @req, @response, current_user: @user
      )
    
  end
  
  should 'list address books' do
    books = [
      FactoryGirl.build(:book, path: 'first'),
      FactoryGirl.build(:book, path: 'second')
    ]
    
    @user.expects(:addressbooks).returns(books)
    children = @res.children()
    children.map(&:path).should == [
      '/first',
      '/second'
    ]
  end
  
  
  
  describe 'HTTP' do
    before do
      user = @user
      app = Rack::Builder.new do
        use XMLSniffer
        run DAV4Rack::Carddav.app('/', current_user: user)
      end
      
      serve_app(app)
    end
    
    should 'return correct path on PROPFIND' do
      books = [
        FactoryGirl.build(:book, path: 'first'),
        FactoryGirl.build(:book, path: 'second')
      ]
      @user.expects(:addressbooks).returns(books)
      
      response = propfind('/books/', [
          ['displayname', @dav_ns]
        ])
      
      ensure_element_exists(response, %{D|response > D|href[text()="/books/first/"]})
      ensure_element_exists(response, %{D|response > D|href[text()="/books/second/"]})
    end
  end
  
end
