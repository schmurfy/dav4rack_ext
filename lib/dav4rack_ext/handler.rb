require 'dav4rack/http_status'

module DAV4RackExt
  class Handler
    # include DAV4Rack::HTTPStatus

    def initialize(options = {})
      @options          = options.dup
      @logger           = options.delete(:logger)
      @controller_class = options.delete(:controller_class) || DAV4Rack::Controller
    end

    def call(env)
      request  = Rack::Request.new(env)
      response = Rack::Response.new

      begin
        controller = @controller_class.new(request, response, @options.dup, env)
        res = controller.send(request.request_method.downcase)
        response.status = res.code if res.respond_to?(:code)

      rescue DAV4Rack::HTTPStatus::Status => status
        response.status = status.code
      end

      response['Content-Length'] = response.body.to_s.bytesize unless response['Content-Length'] || !response.body.is_a?(String)
      response.body = [response.body] unless response.body.respond_to? :each
      response.status = response.status ? response.status.to_i : 200
      response.headers.keys.each do |k|
        response.headers[k] = response[k].to_s
      end

      while request.body.read(8192)
        # Apache wants the body dealt with, so just read it and junk it
      end

      response.finish
    rescue Exception => e
      @logger.error "DAV Error: #{e}\n#{e.backtrace.join("\n")}"
      raise e
    end

  end
end

