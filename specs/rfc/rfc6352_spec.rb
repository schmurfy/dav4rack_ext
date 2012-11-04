require_relative '../spec_helper'

describe 'RFC 6352: CardDav' do
  
  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"
    
    @book = stub('AddressBook', id: '1', name: "A book", created_at: Time.now.iso8601, updated_at: Time.now.iso8601)
    @user = user = stub('User', username: 'john', created_at: Time.now, updated_at: Time.now)
    
    app = Rack::Builder.new do
      use XMLSniffer
      run DAV4Rack::Carddav.app('/', current_user: user)
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
    
    @parsed_vcard = VCardParser::VCard.parse(@vcard_raw).first
  end
  
      
  describe '[6] Address Book Feature' do
    
    describe '[6.1] Address Book Support' do
      it '[6.1] advertise carddav support (MUST include addressbook in DAV header)' do
        response = request(:options, '/')
        response.headers['Dav'].must.include?('addressbook')
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
          @user.expects(:find_addressbook).with('1').returns(@book).times(3) # why so many ???
          @user.expects(:find_contact).with('45GT-JUKL').returns(nil)
          
          contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'ETAG')
          @user.expects(:find_contact).with('1234-5678-9000-1').returns(nil) # Conflict test
          
          @book.expects(:create_contact).returns(contact)
          contact.expects(:update_from_vcard).with do |card|
            card.to_s.should == @vcard_raw
          end
          contact.expects(:save).returns(true)
          
          response = request(:put, '/book/1/45GT-JUKL.vcf', @headers.merge(input: @vcard_raw))
          # 6.3.2.3
          response.headers['ETag'].should == "ETAG"
          
          response.status.should == 201
        end
        
        should 'return an error if contact exists' do
          @user.expects(:find_addressbook).with('1').returns(@book).times(3) # why so many ???
          @user.expects(:find_contact).with('45GT-JUKL').returns(nil)
          
          contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'ETAG')
          @user.expects(:find_contact).with('1234-5678-9000-1').returns(contact) # Conflict test
                  
          response = request(:put, '/book/1/45GT-JUKL.vcf', @headers.merge(input: @vcard_raw))
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
            contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'CONTACT-ETAG', vcard: @parsed_vcard)
            @user.expects(:find_addressbook).with('1').returns(@book)
            @user.expects(:find_contact).with('1234-5678-9000-1').returns(contact)
            response = request(:get, '/book/1/1234-5678-9000-1.vcf')
            response.status.should == 200
            response.headers['ETag'].should == "CONTACT-ETAG"
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
      value.should == '/book/'
      
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
    
  end
  
  
  
  
  describe '[8] Address Book Reports' do
    should 'advertise supported reports (REPORT method)' do
      contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'CONTACT-ETAG', vcard: @parsed_vcard)
      
      @book.expects(:contacts).returns([contact])
      @user.expects(:find_contact).with('1234-5678-9000-1').returns(contact) # wtf ?
      @user.expects(:find_addressbook).with('1').returns(@book).twice
      
      @user.expects(:addressbooks).returns([@book])
      
      response = propfind('/book/', [
          ['supported-report-set', @dav_ns]
        ])
      
      # I hate xml !
      # TODO: find how the hell I can test what I want with nokogiri which is this:
      # <D:supported-report-set>
      #   <D:report>
      #     <C:addressbook-multiget/>
      #   </D:report>
      #   <D:report>
      #     <C:addressbook-query/>
      #   </D:report>
      # </D:supported-report-set>
      value = element_content(response, 'D|addressbook-multiget', 'D' => @carddav_ns)
      value.should == :empty
    end
    
    
    describe '[8.3.1] CARDDAV:supported-collation-set Property' do
      before do
        @contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'CONTACT-ETAG', vcard: @parsed_vcard,
            created_at: Time.now.iso8601, updated_at: Time.now.iso8601
          )
        @user.expects(:find_addressbook).with('1').returns(@book).twice
        @book.expects(:contacts).returns([@contact])
        @user.expects(:find_contact).with('1234-5678-9000-1').returns(@contact) # wtf ?
      end
      
      should 'return supported collations' do
        response = propfind('/book/1', [
            ['supported-collation-set', @carddav_ns]
          ])
        
        elements = ensure_element_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
        elements[0].text.should == ""
      end
        
      should 'not be returned in allprop query' do
        # should not be returned by all
        response = propfind('/book/1')
        
        ensure_element_does_not_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
      end
    end
    
    it '[8.6] CARDDAV:addressbook-query Report' do
      # unsupported for now
    end
    
    
    describe '[8.7] CARDDAV:addressbook-multiget Report' do
      before do
        @contact = stub('Contact', uid: '1234-5678-9000-1', etag: 'CONTACT-ETAG', vcard: @parsed_vcard,
            created_at: Time.now.iso8601, updated_at: Time.now.iso8601
          )

        
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
   <D:href>/book/1/1234-5678-9000-1.vcf</D:href>
   <D:href>/book/1/1234-5678-9000-2.vcf</D:href>
 </C:addressbook-multiget>
        EOS
      end
      
      should 'return multiple cards' do
        @user.expects(:find_addressbook).with('1').returns(@book).times(3) # TODO: 1
        @user.expects(:find_contact).with('1234-5678-9000-1').returns(@contact)
        @user.expects(:find_contact).with('1234-5678-9000-2').returns(nil)
        
        response = request(:report, "/book/1", input: @raw_query, 'HTTP_DEPTH' => '0')
        response.status.should == 207
        
        # '*=' = include
        ensure_element_exists(response, %{D|href[text()*="1234-5678-9000-2"] + D|status[text()*="404"]}, 'D' => @dav_ns)
        
        
        vcard = ensure_element_exists(response, %{D|href[text()*="1234-5678-9000-1"] + D|propstat > D|prop > C|address-data}, 'D' => @dav_ns, 'C' => @carddav_ns)
        vcard.text.should.include? <<-EOS
BEGIN:VCARD
VERSION:3.0
FN:Cyrus Daboo
EMAIL;TYPE=INTERNET,PREF:cyrus@example.com
NICKNAME:me
UID:1234-5678-9000-1
END:VCARD
        EOS
      end
      
      should 'return an error with Depth != 0' do
        @user.expects(:find_addressbook).with('1').returns(@book)
        
        response = request(:report, "/book/1", input: @raw_query, 'HTTP_DEPTH' => '2')
        response.status.should == 400
        
        ensure_element_exists(response, 'D|error > D|invalid-depth', 'D' => @dav_ns)
      end
      
    end
    
    
  end
  
  
end
