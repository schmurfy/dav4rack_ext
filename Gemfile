source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'dav4rack', path: '/Users/schmurfy/Dev/personal/dav4rack'

group(:example) do
  gem 'thin'
  gem 'shotgun'
  gem 'coderay'
  gem 'ox'
end

group(:test) do
  gem 'schmurfy-bacon', path: '/Users/schmurfy/Dev/personal/gems/bacon'
  gem 'mocha',          '~> 0.10.0'
  gem 'factory_girl',   '~> 4.0'
  gem 'virtus'
  
  gem 'simplecov'
  gem 'guard'
  gem 'guard-bacon'
  gem 'rb-fsevent'
  gem 'growl'
  
  # gem 'em-http-request'
  # gem 'faraday'
  # gem 'em-synchrony'
  
  gem 'rack-test'
end
