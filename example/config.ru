
require 'virtus'
require 'http_router'
require 'dav4rack_ext/carddav'
require 'coderay'
require File.expand_path('../rack_sniffer', __FILE__)
require File.expand_path('../../specs/support/models', __FILE__)

use XMLSniffer

class PrefixCatcher
  
  REGEXP = %r{/(?<prefix>[^/]+/())}
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    p env['REQUEST_PATH']
    
    @app.call(env)
  end
end

use PrefixCatcher

contacts = [
  Testing::Contact.new(uid: "12", fields: [
    Testing::Field.new(name: "N", value: "Durand;Christophe;;;"),
    Testing::Field.new(name: "FN", value: "Christophe Durand"),
    Testing::Field.new(name: "TEL", value: "09 87 67 89 33"),
    Testing::Field.new(name: "ADR", value: ";;3 rue du chat;Dris;;90880;FRANCE"),
    Testing::Field.new(name: "BDAY", value: "1900-01-01"),
    Testing::Field.new(name: "X-YAGO-ID", value: "un dromadaire")
  ])
]

USER = Testing::User.new(id: 1, username: 'ja', addressbooks: [
    Testing::AddressBook.new(name: 'default', path: 'default', name: "test 1", contacts: contacts),
    Testing::AddressBook.new(name: 'Second', path: 'second_one', name: "test 2", contacts: []),
  ])


app1 = DAV4Rack::Carddav.app('/cards/',
    logger: Logger.new($stdout, Logger::DEBUG),
    current_user: USER
  )

app2 = DAV4Rack::Carddav.app('/:prefix/cards/',
    logger: Logger.new($stdout, Logger::DEBUG),
    current_user: USER,
    root_uri_path: lambda do |env|
      path = env['REQUEST_PATH']
      n = path.index("/cards/")
      path[0...(n + 7)]
    end
  )

run Rack::Cascade.new([app2])


