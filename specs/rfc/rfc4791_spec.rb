require File.expand_path('../../spec_helper', __FILE__)

describe 'RFC 4791: CalDav' do

  before do
    @dav_ns = "DAV:"
    @carddav_ns = "urn:ietf:params:xml:ns:carddav"

    user_builder = proc do |env|
      contact = FactoryGirl.build(:event, uid: '1234-5678-9000-1')
      contact.stubs(:etag).returns(%("ETAG"))
      contact.stubs(:event).returns(@parsed_event)

      FactoryGirl.build(:user, env: env, login: 'john', calendars: [
        FactoryGirl.build(:calendar, path: 'business', name: "Business events", events: [
          FactoryGirl.build(:event)
        ])
      ])
    end

    app = Rack::Builder.new do
      run DAV4Rack::Carddav.app('/', current_user: user_builder)
    end

    serve_app(app)

    @event_raw = <<-EOS
BEGIN:VCALENDAR
PRODID:-//Example Corp.//CalDAV Client//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:US-Eastern
LAST-MODIFIED:19870101T000000Z
BEGIN:STANDARD
DTSTART:19671029T020000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
TZNAME:Eastern Standard Time (US & Canada)
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19870405T020000
RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
TZNAME:Eastern Daylight Time (US & Canada)
END:DAYLIGHT
END:VTIMEZONE
END:VCALENDAR
    EOS

    @parsed_event = nil # TODO: parse with Ical lib or smth.
  end


  describe '[5] Address Book Feature' do

    describe '[5.1] Address Book Support' do
      it '[5.1] advertise caldav support (MUST include calendar-access in DAV header)' do
        response = request(:options, '/')
        response.headers['Dav'].should.include?('calendar-access')
        response.status.should == 200
      end
    end
  end

  describe '[6] Calendaring Access Control' do
    it '[6.1.1] CALDAV:read-free-busy Privilege' do
      # not implemented
    end

    it '[6.2.1] CALDAV:calendar-home-set Property' do
      response = propfind('/', [
          ['calendar-home-set', @carddav_ns]
        ])

      response.status.should == 207

      value = element_content(response, 'D|calendar-home-set', 'D' => @carddav_ns)
      value.should == '/calendars/'

      # should not be returned by all
      response = propfind('/')
      value = element_content(response, 'D|calendar-home-set', 'D' => @carddav_ns)
      value.should == :missing
    end

    it '[6.2.2] CALDAV:principal-address Property' do
      response = propfind('/', [
          ['principal-address', @carddav_ns]
        ])

      response.status.should == 207

      value = element_content(response, 'D|principal-address', 'D' => @carddav_ns)
      value.should == :empty
    end

  end

  describe '[7] Calendaring Reports' do
    should 'advertise supported reports (REPORT method)' do
      response = propfind('/books/', [
          ['supported-report-set', @dav_ns]
        ])

      elements = ensure_element_exists(response, 'D|supported-report-set > D|report > C|calendar-multiget',
          'D' => @dav_ns, 'C' => @carddav_ns
        )
      elements[0].text.should == ""
    end


    describe '[7.5.1] CALDAV:supported-collation-set Property' do
      should 'return supported collations' do
        response = propfind('/calendars/business', [
            ['supported-collation-set', @carddav_ns]
          ])

        elements = ensure_element_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
        elements[0].text.should == ""
      end

      should 'not be returned in allprop query' do
        # should not be returned by all
        response = propfind('/books/business')

        ensure_element_does_not_exists(response, 'D|supported-collation-set', 'D' => @carddav_ns)
      end
    end

    describe '[8.7] CARDDAV:addressbook-multiget Report' do
      before do
        @contact = FactoryGirl.build(:contact, uid: '1234-5678-9000-1')
        @contact.stubs(:vcard).returns(@parsed_vcard)

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
