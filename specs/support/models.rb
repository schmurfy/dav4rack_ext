require 'virtus'


module Testing
  
  class DummyBase
    include Virtus
    
    attribute :updated_at, Time, default: Time.now
    attribute :created_at, Time, default: Time.now
    
  end


  class Field < DummyBase
    
    attribute :group, String
    attribute :name, String
    attribute :value, String
    attribute :params, Hash, default: {}
    
    
    def self.from_vcf_field(f)
      new(group: f.group, name: f.name, value: f.value, params: f.params)
    end
  end

  class Contact < DummyBase
    
    attribute :uid, String
    attribute :fields, Array[Field], default: []
    
    alias :path :uid
    
    def update_from_vcard(vcf)
      raise "invalid uid" unless vcf['UID'].value == uid
      self.updated_at = Time.now
      
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



  class AddressBook < DummyBase
    
    attribute :name, String
    attribute :path, String
    attribute :contacts, Array[Contact], default: []
    
    def find_contact(uid)
      contacts.detect{|c| c.uid == uid.to_s }
    end
    
    def create_contact(uid)
      Contact.new(uid: uid).tap do |c|
        contacts << c
      end
    end
    
    def updated_at
      Time.now.to_i
    end
    
  end


  class User < DummyBase
    
    attribute :login, String
    attribute :addressbooks, Array[AddressBook], default: []
    
    def find_addressbook(path)
      addressbooks.detect{|b| b.path == path }
    end
    
    def find_contact(uid)
      addressbooks.map(&:contacts).flatten(1).detect{|c| c.uid == uid.to_s }
    end
  end
  
end


