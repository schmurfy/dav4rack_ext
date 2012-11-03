require 'rubygems'
require 'bundler/setup'

require 'bacon'

if ENV['COVERAGE']
  Bacon.allow_focused_run = false
  
  require 'simplecov'
  SimpleCov.start do
    add_filter ".*_spec"
    add_filter "/helpers/"
  end
  
end

$LOAD_PATH.unshift( File.expand_path('../../lib' , __FILE__) )
require 'dav4rack_ext'
require 'rack/test'
require 'factory_girl'

require 'bacon/ext/mocha'


require_relative '../example/rack_sniffer'
require_relative 'support/http'
require_relative 'factories'

Thread.abort_on_exception = true

Bacon.summary_on_exit()

module Rack::Test
  class Session
    def propfind(uri, params = {}, env = {}, &block)
      env = env_for(uri, env.merge(:method => "PROPFIND", :params => params))
      process_request(uri, env, &block)
    end
  end
end



