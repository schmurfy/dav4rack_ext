module HTTPDAVTest
  def propfind(url, properties = :all, opts = {})
    namespaces = {
      'DAV:' => 'D',
      'urn:ietf:params:xml:ns:carddav' => 'C',
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
<D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav" xmlns:APPLE1="http://calendarserver.org/ns/">
  #{body}
</D:propfind>
    EOS
    
    request('PROPFIND', url, opts.merge(input: data))
  end
  
  def ensure_element_exists(response, expr, namespaces = {'D' => 'DAV:'})
    ret = Nokogiri::XML(response.body)
    ret.css(expr, namespaces).tap{|elements| elements.should.not.be.empty? }
  rescue EEtee::AssertionFailed => err
    raise EEtee::AssertionFailed.new("XML did not match: #{expr}")
  end
  
  def ensure_element_does_not_exists(response, expr, namespaces = {})
    ret = Nokogiri::XML(response.body)
    ret.css(expr, namespaces).should.be.empty?
  rescue EEtee::AssertionFailed => err
    raise EEtee::AssertionFailed.new("XML did match: #{expr}")
  end
  
  def element_content(response, expr, namespaces = {})
    ret = Nokogiri::XML(response.body)
    elements = ret.css(expr, namespaces)
    if elements.empty?
      :missing
    else
      children = elements.first.element_children
      if children.empty?
        :empty
      else
        children.first.text
      end
    end
  end
end

EEtee::Context.__send__(:include, HTTPDAVTest)
