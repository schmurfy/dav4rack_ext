require 'eetee'
require 'blink1'

guard 'eetee', blink1: true do
  watch(%r{^lib/dav4rack_ext/(.+)\.rb$})     { |m| "specs/unit/#{m[1]}_spec.rb" }
  watch(%r{specs/.+_spec\.rb$})
end
