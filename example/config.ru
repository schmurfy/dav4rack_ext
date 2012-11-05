
require 'virtus'
require 'http_router'
require 'dav4rack_ext/carddav'
require 'coderay'
require File.expand_path('../rack_sniffer', __FILE__)
require File.expand_path('../../specs/support/models', __FILE__)

use XMLSniffer



contacts = VCardParser::VCard.parse <<-EOS
BEGIN:VCARD
VERSION:3.0
UID:11
N:Ouzme;Raymond;;;
PRODID:-//Apple Inc.//iOS 5.0.1//EN
FN:Raymondine Ouzme
ORG:TestCorp;
TEL:1 24 54 36
REV:2012-10-31T14:49:08Z
END:VCARD

BEGIN:VCARD
VERSION:3.0
UID:88069e04-19bb-425d-a525-faa4171cb394
PRODID:-//Apple Inc.//iOS 5.0.1//EN
N:Durand;Christophe;;;
FN:Christophe Durand
TEL:09 87 67 89 33
ADR:;;3 rue du chat;Dris;;90880;FRANCE
BDAY:1900-01-01
REV:2012-10-31T15:17:21Z
END:VCARD

BEGIN:VCARD
VERSION:3.0
UID:cac90d68-0036-4ef2-bb59-50e38554f21f
PRODID:-//Apple Inc.//iOS 5.0.1//EN
N:Dors;Julie;;;
FN:Julie Dors
TEL:2 50 94 61 3
REV:2012-10-31T15:05:58Z
END:VCARD
EOS

contacts = [
  # Contact.new(id: 1, uid: "11", fields: [
  #   Field.new(name: "N", value: "Charles;Raymond"),
  # ]),
  
  Testing::Contact.new(uid: "12", fields: [
    Testing::Field.new(name: "N", value: "Durand;Christophe;;;"),
    Testing::Field.new(name: "FN", value: "Christophe Durand"),
    Testing::Field.new(name: "TEL", value: "09 87 67 89 33"),
    Testing::Field.new(name: "ADR", value: ";;3 rue du chat;Dris;;90880;FRANCE"),
    Testing::Field.new(name: "BDAY", value: "1900-01-01")
  ])
]

USER = Testing::User.new(id: 1, username: 'ja', addressbooks: [
    Testing::AddressBook.new(name: 'default', path: 'default', name: "test 1", contacts: contacts),
    Testing::AddressBook.new(name: 'Second', path: 'second_one', name: "test 1", contacts: []),
  ])


app = DAV4Rack::Carddav.app('/',
    logger: Logger.new($stdout, Logger::DEBUG),
    current_user: USER
  )

run app

