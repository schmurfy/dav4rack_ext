
require 'virtus'
require 'http_router'
require 'dav4rack_ext/carddav'
require 'coderay'
require File.expand_path('../rack_sniffer', __FILE__)
require File.expand_path('../../specs/support/models', __FILE__)


$contacts = [
  Testing::Contact.new(uid: "777-999", fields: [
    Testing::Field.new(name: "N", value: "Durand;Christophe;;;"),
    Testing::Field.new(name: "FN", value: "Christophe Durand"),
    Testing::Field.new(name: "TEL", value: "09 87 67 89 33", params: {'Type' => ["HOME", "pref"]}),
    Testing::Field.new(name: "ADR", value: ";;3 rue du chat;Dris;;90880;FRANCE"),
    Testing::Field.new(name: "BDAY", value: "1900-01-01"),
    Testing::Field.new(name: "X-YAGO-ID", value: "un dromadaire")
  ])
]

$books = [
  Testing::AddressBook.new(name: 'default', path: 'default', name: "test 1", contacts: $contacts),
  Testing::AddressBook.new(name: 'Second', path: 'second_one', name: "test 2", contacts: []),
]

use XMLSniffer

def create_user(env)
  Testing::User.new(env, id: 1, username: 'ja', addressbooks: $books)
end


# app1 = DAV4Rack::Carddav.app('/cards/',
#     logger: Logger.new($stdout, Logger::DEBUG),
#     current_user: USER
#   )

app2 = DAV4Rack::Carddav.app('/:prefix/cards/',
    logger: Logger.new($stdout, Logger::DEBUG),
    current_user: method(:create_user),
    root_uri_path: lambda do |env|
      path = env['REQUEST_PATH']
      n = path.index("/cards/")
      path[0...(n + 7)]
    end
  )

run Rack::Cascade.new([app2])


