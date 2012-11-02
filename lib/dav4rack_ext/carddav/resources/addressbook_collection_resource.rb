module DAV4Rack
  module Carddav
    
    class AddressbookCollectionResource < AddressbookBaseResource

      def setup
        super
      end

      def exist?
        # Rails.logger.error "ABCR::exist?(#{public_path});"
        return true
      end

      def collection?
        true
      end

      def children
        Logger.debug "ABCR::children(#{public_path})"
        current_user.addressbooks.map do |book|
          child(book.id.to_s)
        end
      end
      
    end
    
  end
end
