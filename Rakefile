require 'rubygems'
require 'bundler/setup'
require "bundler/gem_tasks"

task :default => :test

task :test do
  
  # do not generate coverage report under travis
  unless ENV['TRAVIS']
    
    require 'simplecov'
    SimpleCov.command_name "E.T."
    SimpleCov.start do
      add_filter ".*_spec"
      add_filter "/helpers/"
    end
  end
  
  require 'eetee'
  
  runner = EEtee::Runner.new
  runner.run_pattern('specs/**/*_spec.rb')
  runner.report_results()
  
end

