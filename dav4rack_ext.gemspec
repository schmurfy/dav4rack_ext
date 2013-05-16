# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dav4rack_ext/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julien Ammous"]
  gem.email         = ["schmurfy@gmail.com"]
  gem.description   = %q{CardDAV / CalDAV implementation}
  gem.summary       = %q{CardDAV / CalDAV implementation.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "dav4rack_ext"
  gem.require_paths = ["lib"]
  gem.version       = Dav4rackExt::VERSION
  
  gem.add_dependency 'dav4rack'
  gem.add_dependency 'http_router'
  gem.add_dependency 'vcard_parser', '0.0.7'
end
