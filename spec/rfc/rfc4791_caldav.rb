require 'spec_helper'

describe 'RFC 4791: CalDav' do
  let :raw_event do
    <<-EOS
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
UID:1234-5678-9000-1
END:DAYLIGHT
END:VTIMEZONE
END:VCALENDAR
    EOS
  end

  let :event do
    double 'Event', etag: Time.now,
                    path: '1234-5678-9000-1',
                    created_at: Time.now,
                    updated_at: Time.now,
                    to_ical: raw_event
  end

  let :event_2 do
    double 'Event', etag: Time.now,
                    path: '1234-5678-9000-2',
                    created_at: Time.now,
                    updated_at: Time.now,
                    to_ical: raw_event
  end

  let :calendar do
    double 'Calendar', path: 'business',
                       description: 'Business Calendar',
                       ctag: Time.now,
                       events: [event, event_2],
                       created_at: Time.now,
                       updated_at: Time.now
  end

  let :user do
    d = double 'User', login: 'john',
                       calendars: [calendar]

    d.stub(:call).and_return d
    d
  end

  let :dav_ns do
    "DAV:"
  end

  let :caldav_ns do
    "urn:ietf:params:xml:ns:caldav"
   end

  before do
    current_user = user

    app = Rack::Builder.new do
      run DAV4Rack::Caldav.app('/', current_user: current_user)
    end

    serve_app(app)
  end

  describe '[1.2]' do
    it 'uses the caldav namespace' do
      pending 'check for urn:ietf:params:xml:ns:caldav'
    end
  end

  describe '[5] Calendar Access Feature' do
    describe '[5.1] Calendar Access Support' do
      it 'includes "calendar-access" as a field in the DAV response header' do
        response = request :options, '/'
        expect(response.headers['Dav']).to include 'calendar-access'
        expect(response.status).to eq 200
      end
    end

    describe '[5.2] Calendar Collection Properties' do
      it '[5.2.1] CALDAV:calendar-description Property'
      it '[5.2.2] CALDAV:calendar-timezone Property'
      it '[5.2.3] CALDAV:supported-calendar-component-set Property'
      it '[5.2.4] CALDAV:supported-calendar-data Property'
      it '[5.2.5] CALDAV:max-resource-size Property'
      it '[5.2.6] CALDAV:min-date-time Property'
      it '[5.2.7] CALDAV:max-date-time Property'
      it '[5.2.8] CALDAV:max-instances Property'
      it '[5.2.9] CALDAV:max-attendees-per-instance Property'
      it '[5.2.10] Additional Precondition for PROPPATCH'
    end

    describe '[5.3] Creating Resources' do
      pending 'not implemented'
    end
  end

  describe '[6] Calendaring Access Control' do

    describe '[6.1] Calendaring Privilege' do
      it '[6.1.1] CALDAV:read-free-busy Privilege'
    end

    describe '[6.2] Additional Principal Property' do
      it '[6.2.1] CALDAV:calendar-home-set Property' do
        response = propfind('/', [['calendar-home-set', caldav_ns]])

        expect(response.status).to eq 207
        expect(response.body).to have_element('D|calendar-home-set', 'D' => caldav_ns)

        value = find_content(response.body, 'D|calendar-home-set', 'D' => caldav_ns)
        expect(value).to eq '/calendars/'
      end

      it '[6.2.2] CALDAV:principal-address Property' do
        response = propfind('/', [['principal-address', caldav_ns]])

        expect(response.status).to eq 207
        expect(response.body).to have_element('D|principal-address', 'D' => caldav_ns)

        value = find_content(response.body, 'D|principal-address', 'D' => caldav_ns)
        expect(value).to eq ''
      end
    end
  end

  describe '[7] Calendaring Reports' do
    it 'advertises the supported reports (REPORT method)' do
      response = propfind('/calendars/', [['supported-report-set', dav_ns]])

      expect(response.body).to have_element('D|supported-report-set > D|report > C|calendar-multiget',
        'D' => dav_ns, 'C' => caldav_ns)

      elements = find_element(response.body, 'D|supported-report-set > D|report > C|calendar-multiget',
        'D' => dav_ns, 'C' => caldav_ns
      )
      expect(elements[0].text).to eq ''
    end

    describe '[7.5] Searching Text: Collations' do
      describe '[7.5.1] CALDAV:supported-collation-set Property' do
        it 'returns supported collations' do
          response = propfind('/calendars/business', [
              ['supported-collation-set', caldav_ns]
            ])

          expect(response.body).to have_element('D|supported-collation-set', 'D' => caldav_ns)

          elements = find_element(response.body, 'D|supported-collation-set', 'D' => caldav_ns)
          expect(elements[0].text).to eq ''
        end

        it 'is not returned in allprop query' do
          response = propfind('/calendars/business')
          expect(response.body).not_to have_element('D|supported-collation-set', 'D' => caldav_ns)
        end
      end
    end

    describe '[7.8] CALDAV:calendar-query REPORT' do
      before do
        @raw_query = %q{
          <?xml version="1.0" encoding="utf-8" ?>
          <A:calendar-query xmlns:A="urn:ietf:params:xml:ns:caldav" xmlns:B="DAV:">
            <B:prop>
              <B:getcontenttype/>
              <B:getetag/>
            </B:prop>
            <A:filter>
              <A:comp-filter name="VCALENDAR">
                <A:comp-filter name="VEVENT">
                  <A:time-range start="20140402T000000Z" end="20141126T000000Z"/>
                </A:comp-filter>
              </A:comp-filter>
            </A:filter>
          </A:calendar-query>
        }
      end

      it 'filters by date range' do
        response = request(:report, '/calendars/business', input: @raw_query, 'HTTP_DEPTH' => 1)

        expect(response.body).to include '<D:getetag>'
        expect(response.body).to include '<C:calendar-data>'
        expect(response.body).to include '<D:status>HTTP/1.0 200 OK</D:status>'
        expect(response.body).to include "<D:href>/calendars/business/#{event.path}.ics</D:href>"
      end
    end

    describe '[7.9] CALDAV:calendar-multiget Report' do
      before do
        @raw_query = %q{
           <?xml version="1.0" encoding="utf-8" ?>
           <C:calendar-multiget xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
             <D:prop>
               <D:getetag/>
               <C:calendar-data/>
             </D:prop>
             <D:href>/calendars/business/1234-5678-9000-1.ics</D:href>
           </C:calendar-multiget>
        }
      end

      it 'returns calendar data' do
        response = request(:report, "/calendars/business", input: @raw_query, 'HTTP_DEPTH' => '0')
        expect(response.status).to eq 207

        expect(response.body).to include '<C:calendar-data>'
        expect(response.body).to include 'BEGIN:VCALENDAR'
        expect(response.body).to include 'UID:1234-5678-9000-1'
      end

      it 'returns an error with Depth != 0' do
        response = request(:report, "/calendars/business", input: @raw_query, 'HTTP_DEPTH' => '2')
        expect(response.status).to eq 400
        expect(response.body).to have_element 'D|error > D|invalid-depth', 'D' => dav_ns
      end
    end
  end
end
