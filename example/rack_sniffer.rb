require 'ox'
require 'rack/request'
require 'coderay'

class XMLSniffer
  PREFIX = " " * 4
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    ret = nil
    ret = @app.call(env)
    
  ensure
    request = Rack::Request.new(env)
    puts "\n*** REQUEST ( #{request.request_method} #{request.path} ) ***"
    request.body.rewind
    dump_headers(env)
    
    body = request.body.read
    request.body.rewind
    
    unless body.empty?
      dump_xml(body)
    end
    
    if ret
      if ret[2].respond_to?(:body) && !ret[2].body.empty? && !ret[-1].body[0].empty?
        puts "\n    --- RESPONSE (#{ret[0]}) ---"
        ret[1].each do |name, value|
          puts "#{name} = #{value}"
        end
        
        dump_xml(ret[-1].body[0])
      else
        puts "\n    --- EMPTY RESPONSE (#{ret[0]}) ---"
        ret[1].each do |name, value|
          puts "#{name} = #{value}"
        end
      end
    end
    
    ret
  end
  
private
  def dump_headers(env)
    extract_headers(env).each do |name, value|
      puts "#{name} = #{value}"
    end
  end

  def dump_xml(str)
    doc = Ox.parse(str)
    source = Ox.dump(doc)
    puts ""
    puts CodeRay.scan(source, :xml).term
  rescue SyntaxError, Ox::ParseError
    puts "\n#{str}"
  end
  
  def extract_headers(env)
    headers = env.select {|k,v| k.start_with?('HTTP_') || (k[0].upcase == k[0])}
    headers.map do |pair|
      [pair[0].ljust(20), pair[1]]
    end
  end
  
end
