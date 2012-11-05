module DAV4Rack
  module Carddav
    
    class AddressbookCollectionResource < AddressbookBaseResource
      
      def exist?
        return true
      end

      def collection?
        true
      end

      def children
        current_user.addressbooks.map do |book|
          child(book)
        end
      end
      
      def child(name)
        super(AddressbookResource, name)
      end
      
    end
    
  end
end
