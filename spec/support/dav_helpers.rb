require 'nokogiri'
require 'rspec/expectations'
require 'rack/test'

RSpec::Matchers.define :have_element do |expression, namespaces|
  match do |actual|
    !find_element(actual, expression, namespaces).empty?
  end
end

RSpec::Matchers.define :include_content do |expression, namespaces|
  match do |actual|
    elements = find_element(actual, expression, namespaces)
    !elements.empty
  end
end

RSpec::Matchers.define :empty_content do |expression, namespaces|
  match do |actual|
    elements = find_element(actual, expression, namespaces)
    children = elements.first.element_children
    children.empty?
  end
end

module DavHelpers
  def find_element(body, expression, namespaces)
    ret = Nokogiri::XML(body)
    ret.css(expression, namespaces)
  end

  def find_content(body, expression, namespaces)
    elements = find_element(body, expression, namespaces)
    children = elements.first.element_children
    children.first.text
  end

  def serve_app(app)
    @app = Rack::Test::Session.new(Rack::MockSession.new(app))
  end

  def request(method, url, opts = {})
    @app.request(url, opts.merge(method: method))
    @app.last_response
  end

  def propfind(url, properties = :all, opts = {})
    namespaces = {
      'DAV:' => 'D',
      'urn:ietf:params:xml:ns:caldav' => 'C',
      'http://calendarserver.org/ns/' => 'APPLE1'
    }

    if properties == :all
      body = "<D:allprop />"

    else
      properties = properties.map do |(name, ns)|
        ns_short = namespaces[ns]
        raise "unknown namespace: #{ns}" unless ns_short
        %.<#{ns_short}:#{name}/>.
      end

      body = "<D:prop>#{properties.join("\n")}</D:prop>"
    end


    data = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav" xmlns:APPLE1="http://calendarserver.org/ns/">
  #{body}
</D:propfind>
    EOS

    request('PROPFIND', url, opts.merge(input: data))
  end
end
