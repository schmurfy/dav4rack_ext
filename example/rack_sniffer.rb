require 'rack/request'
require 'coderay'

class XMLSniffer
  PREFIX = " " * 4
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    ret = @app.call(env)
    request = Rack::Request.new(env)
    
    puts "*** REQUEST ( #{request.request_method} #{request.path} ) ***"
    request.body.rewind
    dump_headers(env)
    dump_xml(request.body.read)
    request.body.rewind
    
    unless ret[2].body.empty?
      puts "\n*** RESPONSE ***"
      ret[1].each do |name, value|
        puts "#{name} = #{value}"
      end
      
      dump_xml(ret[-1].body[0])
    else
      puts "\n*** EMPTY RESPONSE ***"
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
    puts ""
    puts CodeRay.scan(str, :xml).term
  end
  
  def extract_headers(env)
    env.select {|k,v| k.start_with? 'HTTP_'}
      .collect {|pair| [pair[0].sub(/^HTTP_/, ''), pair[1]]}
  end
  
end
