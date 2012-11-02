
require 'virtus'
require 'http_router'
require 'dav4rack_ext/carddav'
require 'coderay'
require File.expand_path('../rack_sniffer', __FILE__)


use XMLSniffer

class Field
  include Virtus
  
  attribute :id, Integer
  attribute :contact_id, Integer
  attribute :group, String
  attribute :name, String
  attribute :value, String
  attribute :params, Hash, default: {}
  
  
  def self.from_vcf_field(f)
    new(group: f.group, name: f.name, value: f.value, params: f.params)
  end
end

class Contact
  include Virtus
  
  attribute :id, Integer
  attribute :uid, String
  attribute :addressbook_id, Integer
  attribute :fields, Array[Field], default: []
  
  def update_from_vcard(vcf)
    raise "invalid uid" unless vcf['UID'].value == uid
    
    # TODO: addressbook rename fields
    
    vcf.each_field do |a|
      existing_field = fields.detect do |f|
        (f.name == a.name) && (f.group == a.group) && (f.params == a.params)
      end
      
      if existing_field
        puts "Updated '#{a.group}.#{a.name}' to '#{a.value}'"
        existing_field.value = a.value
      else
        puts "Created '#{a.group}.#{a.name}' with '#{a.value}'"
        fields << Field.from_vcf_field(a)
      end
    end
    
  end
  
  def save
    p fields
    
    # no-op
    true
  end
  
  def destroy
    true
  end
  
  def etag
    rand(1000).to_s
  end
  
  def vcard
    vcard = VCardParser::VCard.new("3.0")
    vcard.add_field('UID', uid)
    
    fields.each do |f|
      puts "[vCard] Adding field #{f.name} / #{f.value} / #{f.group} / #{f.params}"
      vcard.add_field(f.name, f.value, f.group, f.params)
    end
    
    vcard
  end
  
end

class AddressBook
  include Virtus
  
  attribute :id, Integer
  attribute :user_id, Integer
  attribute :name, String
  
  attribute :contacts, Array[Contact], default: []
  
  def find_contact(uid)
    contacts.detect{|c| c.uid == uid.to_s }
  end
  
  def create_contact(uid)
    c = Contact.new(
        uid:            uid,
        addressbook_id: id
      )
    contacts << c
    c
  end
  
  def updated_at
    Time.now
  end
end


class User
  include Virtus
  
  attribute :id, Integer
  attribute :username, String
  
  attribute :addressbooks, Array[AddressBook], default: []
  
  def find_addressbook(id)
    addressbooks.detect{|b| b.id == id.to_i }
  end
  
  def find_contact(uid)
    addressbooks.map(&:contacts).flatten(1).detect{|c| c.uid == uid.to_s }
  end
end

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
  
  Contact.new(id: 12, uid: "12", fields: [
    Field.new(name: "N", value: "Durand;Christophe;;;"),
    Field.new(name: "FN", value: "Christophe Durand"),
    Field.new(name: "TEL", value: "09 87 67 89 33"),
    Field.new(name: "ADR", value: ";;3 rue du chat;Dris;;90880;FRANCE"),
    Field.new(name: "BDAY", value: "1900-01-01")
  ])
]

USER = User.new(id: 1, username: 'ja', addressbooks: [
    AddressBook.new(id: 1, name: "test 1", user_id: 1, contacts: contacts)
  ])

current_user = ->{ USER }
logger = Logger.new($stdout, Logger::DEBUG)

dav_extensions = ["access-control", "addressbook"]

router = HttpRouter.new do |r|

  r.add('/carddav/').to DAV4Rack::Handler.new(
      :log_to                   => logger,
      :dav_extensions           => dav_extensions,
      :alway_include_dav_header => true,
      :pretty_xml               => true,
      :root                     => '/carddav',
      :root_uri_path            => '/carddav',
      :resource_class           => DAV4Rack::Carddav::PrincipalResource,
      :current_user             => current_user
    )
  
  r.add('/book/:book_id/:contact_id(.vcf)').to DAV4Rack::Handler.new(
      :log_to                   => logger,
      :dav_extensions           => dav_extensions,
      :alway_include_dav_header => true,
      :pretty_xml               => true,
      :root                     => '/book',
      :root_uri_path            => '/book',
      :resource_class           => DAV4Rack::Carddav::ContactResource,
      :addresbook_model         => AddressBook,
      :contact_model            => Contact,
      :current_user             => current_user
    )
  
  r.add('/book/:book_id').to DAV4Rack::Handler.new(
      :additional_verbs         => ['report'],
      :log_to                   => logger,
      :dav_extensions           => dav_extensions,
      :alway_include_dav_header => true,
      :pretty_xml               => true,
      :root                     => '/book',
      :root_uri_path            => '/book',
      :resource_class           => DAV4Rack::Carddav::AddressbookResource,
      :addresbook_model         => AddressBook,
      :contact_model            => Contact,
      :current_user             => current_user
    )
  
  r.add('/book/').to DAV4Rack::Handler.new(
      :log_to                   => logger,
      :dav_extensions           => dav_extensions,
      :alway_include_dav_header => true,
      :pretty_xml               => true,
      :root                     => '/book',
      :root_uri_path            => '/book',
      :resource_class           => DAV4Rack::Carddav::AddressbookCollectionResource,
      :addresbook_model         => AddressBook,
      :contact_model            => Contact,
      :current_user             => current_user
    )
end

run router
