module DAV4Rack
  module Carddav

    class AddressbookCollectionResource < Resource

      def exist?
        true
      end

      def collection?
        true
      end

      def children
        current_user.all_addressbooks.map do |book|
          child(AddressbookResource, book)
        end
      end

    end

  end
end
