require 'rubygems'
require 'bundler/setup'

require 'eetee'

$LOAD_PATH.unshift( File.expand_path('../../lib' , __FILE__) )
require 'dav4rack_ext'
require 'factory_girl'


require 'eetee/ext/mocha'
require 'eetee/ext/rack'

require_relative 'helpers/http_dav'

require_relative '../example/rack_sniffer'
require_relative 'support/models'
require_relative 'factories'

Thread.abort_on_exception = true


module Rack::Test
  class Session
    def propfind(uri, params = {}, env = {}, &block)
      env = env_for(uri, env.merge(:method => "PROPFIND", :params => params))
      process_request(uri, env, &block)
    end
  end
end



