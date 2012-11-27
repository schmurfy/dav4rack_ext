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
  gem 'eetee',          '= 0.0.1'
  gem 'mocha',          '~> 0.12.0'
  gem 'factory_girl',   '~> 4.0'
  gem 'virtus'
  
  gem 'simplecov'
  gem 'guard',          '~> 1.5.4'
  gem 'rb-fsevent'
  gem 'growl'
    
  gem 'rack-test',      '~> 0.6.2'
end
