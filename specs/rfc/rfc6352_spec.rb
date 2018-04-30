require File.expand_path('../../spec_helper', __FILE__)

describe 'RFC 6352: CardDav' do
  
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    user_builder = proc do |env|
      contact = FactoryGirl.build(:contact, uid: '1234-5678-9000-1')
      contact.stubs(:etag).returns('ETAG')
      contact.stubs(:vcard).returns(@parsed_vcard)
      
      FactoryGirl.build(:user, env: env, login: 'john', addressbooks: [
          FactoryGirl.build(:book, path: 'castor', name: "A book", contacts: [contact])
        ])
    end
    
    app = Rack::Builder.new do
      # use XMLSniffer
      run DAV4Rack::Carddav.app('/', current_user: user_builder)
    end
    
    serve_app(app)
    
    @vcard_raw = <<-EOS
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
    
    
    @vcard_raw2 = <<-EOS
BEGIN:VCARD
VERSION:3.0
FN:John Doe
N:John;Doe
ADR;TYPE=POSTAL:;2822 Email HQ;Suite 2821;RFCVille;PA;15213;USA
EMAIL;TYPE=INTERNET,PREF:cyrus@example.com
NOTE:Example VCard.
ORG:Self Employed
TEL;TYPE=WORK,VOICE:412 605 0499
TEL;TYPE=FAX:412 605 0705
URL:http://www.example.com
UID:1234-5678-9000-9
END:VCARD
    EOS
    
    @parsed_vcard = VCardParser::VCard.parse(@vcard_raw).first
  end
  
      
  describe '[6] Address Book Feature' do
    
    describe '[6.1] Address Book Support' do
      it '[6.1] advertise carddav support (MUST include addressbook in DAV header)' do
        response = request(:options, '/')
        response.headers['Dav'].should.include?('addressbook')
        response.status.should == 200
      end
    end
    
    describe '[6.2] AddressBook properties' do
    
      it '[6.2.1] CARDDAV:addressbook-description' do
      #   request('/', method: 'OPTIONS')
      end
      
      it '[6.2.3] CARDDAV:max-resource-size' do
        
      end
      
    end
    
    
    
    describe '[6.3] Creating Resources' do
      
      it '[6.3.1] Extended MKCOL Method' do
        # optional
      end
      
      describe '[6.3.2] Creating Address Object Resources' do
        before do
          @headers = {
            'HTTP_IF_NONE_MATCH' => '*'
          }
        end
        
        should 'create contact' do
          Testing::Contact.any_instance.expects(:etag).returns("ETAG")
          
          # the url does not need to match the UID
          response = request(:put, '/books/castor/new.vcf', @headers.merge(input: @vcard_raw2))
          response.status.should == 201
          
          # 6.3.2.3
          response.headers['ETag'].should == "ETAG"
        end
        
        should 'return an error if contact exists' do
          response = request(:put, '/books/castor/new.vcf', @headers.merge(input: @vcard_raw))
          response.status.should == 409 # Conflict
        end
        
        
        describe '[6.3.2.1] Additional Preconditions for PUT, COPY, and MOVE' do
          should 'enforce CARDDAV:supported-address-data' do
            
          end
          
          should 'enforce CARDDAV:valid-address-data' do
            
          end
          
          should 'enforce CARDDAV:no-uid-conflict' do
            
          end
          
          should 'enforce CARDDAV:max-resource-size' do
            
          end
        end
        
        
        describe '[6.3.2.3] Address Object Resource Entity Tag' do
          should 'set Etag header on GET' do
            response = request(:get, '/books/castor/1234-5678-9000-1.vcf')
            response.status.should == 200
            response.headers['ETag'].should == "ETAG"
          end
          
        end
        
      end
    end
  
  end
  
  
  
  
  
  
  describe '[7] Address Book Access Control' do
    
    it '[7.1.1] CARDDAV:addressbook-home-set Property' do
      response = propfind('/', [
          ['addressbook-home-set', @carddav_ns]
        ])
            
      response.status.should == 207
      
      value = element_content(response, 'D|addressbook-home-set', 'D' => @carddav_ns)
      value.should == '/books/'
      
      # should not be returned by all
      response = propfind('/')
      value = element_content(response, 'D|addressbook-home-set', 'D' => @carddav_ns)
      value.should == :missing
    end
    
    it '[7.1.2] CARDDAV:principal-address Property' do
      response = propfind('/', [
          ['principal-address', @carddav_ns]
        ])
            
      response.status.should == 207
      
      value = element_content(response, 'D|principal-address', 'D' => @carddav_ns)
      value.should == :empty
    end
    
    it 'DAV:sync-token', focus: true do
      response = propfind('/books/castor', [
          ['displayname', @dav_ns],
          ['sync-token', @dav_ns]
        ])
            
      response.status.should == 207
      
      puts response.body
      
      value = element_content(response, 'D|sync-token', 'D' => @carddav_ns)
      value.should == 'TOTO'

    end
  end
  
  
  
  
  describe '[8] Address Book Reports' do
    should 'advertise supported reports (REPORT method)' do
      response = propfind('/books/', [
          ['supported-report-set', @dav_ns]
        ])
      
      elements = ensure_element_exists(response, 'D|supported-report-set > D|report > C|addressbook-multiget',
          'D' => @dav_ns, 'C' => @carddav_ns
        )
      elements[0].text.should == ""
    end
    
    
    describe '[8.3.1] CARDDAV:supported-collation-set Property' do
      should 'return supported collations' do
        response = propfind('/books/castor', [
            ['supported-collation-set', @carddav_ns]
          ])
        
        elements = ensure_element_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
        elements[0].text.should == ""
      end
        
      should 'not be returned in allprop query' do
        # should not be returned by all
        response = propfind('/books/castor')
        
        ensure_element_does_not_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
      end
    end
    
    describe '[8.6] CARDDAV:addressbook-query Report' do
      before do
        # @contact1 = FactoryGirl.build(:contact, uid: '1234-5678-9000-1')
        # @contact2 = FactoryGirl.build(:contact, uid: '1234-5678-9000-2')
      end
      
      should 'return results' do
        response = report('/books/castor', %w(UID EMAIL FN))
        # puts response.body
        elements = ensure_element_exists(response, 'D|multistatus > D|response', 'D' => @dav_ns)
        
        elements[0].tap do |el|
          el.css('D|href', 'D' => @dav_ns).first.content.should == "/books/castor/1234-5678-9000-1"
          el.css('D|getetag', 'D' => @dav_ns).first.content.should == "ETAG"
        end
        
      end
    end
    
    
    describe '[8.7] CARDDAV:addressbook-multiget Report' do
      before do
        # @contact = FactoryGirl.build(:contact, uid: '1234-5678-9000-1')
        # @contact.stubs(:vcard).returns(@parsed_vcard)

        
        @raw_query = <<-EOS
 <?xml version="1.0" encoding="utf-8" ?>
 <C:addressbook-multiget xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav">
   <D:prop>
     <D:getetag/>
     <C:address-data>
       <C:prop name="VERSION"/>
       <C:prop name="UID"/>
       <C:prop name="NICKNAME"/>
       <C:prop name="EMAIL"/>
       <C:prop name="FN"/>
     </C:address-data>
   </D:prop>
   <D:href>/books/castor/1234-5678-9000-1.vcf</D:href>
   <D:href>/books/castor/1234-5678-9000-2.vcf</D:href>
 </C:addressbook-multiget>
        EOS
      end
      
      should 'return multiple cards' do
        response = request(:report, "/books/castor", input: @raw_query, 'HTTP_DEPTH' => '0')
        response.status.should == 207
        
        # '*=' = include
        ensure_element_exists(response, %{D|href[text()*="1234-5678-9000-2"] + D|status[text()*="404"]}, 'D' => @dav_ns)
        
        # <D:getetag>"23ba4d-ff11fb"</D:getetag>
        etag = ensure_element_exists(response, %{D|href[text()*="1234-5678-9000-1"] + D|propstat > D|prop > D|getetag}, 'D' => @dav_ns)
        etag.text.should == 'ETAG'
        
        vcard = ensure_element_exists(response, %{D|href[text()*="1234-5678-9000-1"] + D|propstat > D|prop > C|address-data}, 'D' => @dav_ns, 'C' => @carddav_ns)
        vcard.text.should.include? <<-EOS
BEGIN:VCARD
VERSION:3.0
FN:Cyrus Daboo
EMAIL;type=INTERNET,PREF:cyrus@example.com
NICKNAME:me
UID:1234-5678-9000-1
END:VCARD
        EOS
      end
      
      should 'return an error with Depth != 0' do
        response = request(:report, "/books/castor", input: @raw_query, 'HTTP_DEPTH' => '2')
        response.status.should == 400
        
        ensure_element_exists(response, 'D|error > D|invalid-depth', 'D' => @dav_ns)
      end
      
    end
    
    
  end
  
  
end
