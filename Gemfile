source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'dav4rack', git: 'git://github.com/schmurfy/dav4rack.git', branch: 'parent_collection'

group(:example) do
  gem 'thin'
  gem 'shotgun'
  gem 'coderay'
  gem 'ox'
end

group(:local) do
  gem 'rb-blink1'
end

group(:test) do
  gem 'eetee',          '~> 0.0.5'
  gem 'mocha',          '~> 0.12.0'
  gem 'factory_girl',   '~> 4.0'
  gem 'virtus'
  
  gem 'simplecov'
  gem 'guard',          '~> 1.5.4'
  gem 'rb-fsevent'
  gem 'growl'
    
  gem 'rack-test',      '~> 0.6.2'
end
