FactoryGirl.define do
  
  factory(:contact, :class => Testing::Contact) do
    created_at Time.now
    updated_at Time.now
  end
    
  factory(:user, :class => Testing::User) do
    created_at Time.now
    updated_at Time.now
    
    initialize_with { new(env) }
  end
  
  factory(:book, :class => Testing::AddressBook) do
    created_at Time.now
    updated_at Time.now
  end
  
end
