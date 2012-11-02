require_relative '../../../spec_helper'

describe 'RFC 6352: CardDav' do
  before do
    @book = stub('AddressBook')
    @user = user = stub('User', username: 'john')
    @toto = 43
    
    app = Rack::Builder.new do
      use XMLSniffer
      run DAV4Rack::Carddav.app(current_user: user)
    end
    
    @app = Rack::Test::Session.new(
        Rack::MockSession.new(app)
      )
    
  end
      
  describe '[6.1] Address Book Support' do
    it '[6.1] advertise carddav support (MUST include addressbook in DAV header)' do
      @app.request('/carddav/', method: 'OPTIONS')
      @app.last_response.headers['Dav'].must.include?('addressbook')
      @app.last_response.status.should == 200
    end
  end
  
  describe '[6.2] AddressBook properties' do
  
    it '[6.2.1] CARDDAV:addressbook-description' do
    #   request('/carddav/', method: 'OPTIONS')
    end
    
    it '[6.2.3] CARDDAV:max-resource-size' do
      
    end
    
  end
  
  
  
  describe '[6.3] Creating Resources' do
    
    it '[6.3.1] Extended MKCOL Method' do
      # optional
    end
    
    it '[6.3.2] Creating Address Object Resources' do
      headers = {
        'HTTP_IF_NONE_MATCH' => '*'
      }
      
      # @user.expects(:find_addressbook).with('1').returns(@book)
      @book.expects(:find_contact).with('45GT-JUKL').returns(nil)
      
      @app.request('/book/1/45GT-JUKL.vcf', headers.merge(method: 'PUT', input: <<-EOS))
BEGIN:VCARD
VERSION:3.0
FN:Cyrus Daboo
N:Daboo;Cyrus
ADR;TYPE=POSTAL:;2822 Email HQ;Suite 2821;RFCVille;PA;15213;USA
EMAIL;TYPE=INTERNET,PREF:cyrus@example.com
NICKNAME:me
NOTE:Example VCard.
ORG:Self Employed
TEL;TYPE=WORK,VOICE:412 605 0499
TEL;TYPE=FAX:412 605 0705
URL:http://www.example.com
UID:1234-5678-9000-1
END:VCARD
      EOS
      
      @pp.last_response.status.should ==201
    end
  end
  
end
