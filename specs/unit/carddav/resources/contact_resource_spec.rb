require File.expand_path('../../../../spec_helper', __FILE__)

describe 'Contact Resource' do
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    @contact = contact = FactoryGirl.build(:contact, uid: '1234-5678-9000-1')

    
    user_builder = proc do |env|      
      FactoryGirl.build(:user, env: env, login: 'john', addressbooks: [
          FactoryGirl.build(:book, path: 'castor', name: "A book", contacts: [contact])
        ])
    end
        
    app = Rack::Builder.new do
      # use XMLSniffer
      run DAV4Rack::Carddav.app('/', current_user: user_builder)
    end
    
    serve_app(app)
  end
  
  should 'update contact and return correct location', :force => true do
    # the url does not need to match the UID
    response = request(:put, '/books/castor/crap',
        input: @contact.vcard.to_s
      )
    
    response.status.should == 201
    response.headers['Location'].should == 'http://example.org:80/books/castor/1234-5678-9000-1'
  end
  
  should 'return an error if If-Match do not match (rfc2068 14.25)' do
    Testing::Contact.any_instance.expects(:etag).returns("ETAG")
    
    headers = {
      'HTTP_IF_MATCH' => 'ETAG2'
    }
    
    # the url does not need to match the UID
    response = request(:put, '/books/castor/1234-5678-9000-1',
        headers.merge(input: @contact.vcard.to_s)
      )
    
    response.status.should == 412
  end
  
  should 'return an error with If-Match and no contact (rfc2068 14.25)' do
    headers = {
      'HTTP_IF_MATCH' => 'ETAG2'
    }
    
    c = @contact.dup
    c.uid = '55TT'
    
    # the url does not need to match the UID
    response = request(:put, '/books/castor/CRAP',
        headers.merge(input: c.vcard.to_s)
      )
    
    response.status.should == 412
  end

  
  should 'update contact if If-Match="*" and contact was found (rfc2068 14.25)' do
    headers = {
      'HTTP_IF_MATCH' => '*'
    }
    
    # the url does not need to match the UID
    response = request(:put, '/books/castor/1234-5678-9000-1',
        headers.merge(input: @contact.vcard.to_s)
      )
    
    response.status.should == 201
  end
  
  should 'not update contact if If-Match="*" and no contact found (rfc2068 14.25)' do
    headers = {
      'HTTP_IF_MATCH' => '*'
    }
    
    c = @contact.dup
    c.uid = '55TT'
    
    # the url does not need to match the UID
    response = request(:put, '/books/castor/undefined',
        headers.merge(input: c.vcard.to_s)
      )
    
    response.status.should == 412
  end
  
end
