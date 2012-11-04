module DAV4Rack
  module Carddav
    
    # This class has some stuff common to the address books, their collections, and contacts
    class AddressbookBaseResource < Resource
          
      # name:: Name of child
      # Create a new child with the given name
      # NOTE:: Include trailing '/' if child is collection  
      def child(name)
        new_public = public_path.dup
        new_public = new_public + '/' unless new_public[-1,1] == '/'
        new_public = '/' + new_public unless new_public[0,1] == '/'
        new_path = path.dup
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'

        # This is gross and we should be checking the desired new path directly
        klass = self.class
        if @is_root
          klass = AddressbookResource
        elsif @is_book
          klass = ContactResource
        end
        
        Logger.debug "[#{@book_path}] CHILD(#{name}): is_contact = #{@is_card}; is_book = #{@is_book}; is_root = #{@is_root}"
        Logger.debug "=> #{klass}"

        klass.new("#{new_public}#{name}", "#{new_path}#{name}", request, response, options.merge(:user => @user))
      end

      def setup
        super

        # Rails.logger.error "PUBLIC PATH '#{@public_path.inspect}'"
        # Rails.logger.error "NEW PUBLIC PATH '#{@public_path.inspect}'"

        path_str = @public_path.dup
        @book_path = nil
        
        # /book/1/

        # Determine what type of path it is
        @is_root = @is_book = @is_card = false
        case path_str
        when %r{^/book/[0-9]+/.+}
          # is_card (/book/:book_id/:card_uid)
          @book_path = Pathname(path_str).parent.split.last.to_s
          @is_card = true
          Logger.debug("[#{self.class.name}] #{path_str} is a card ! #{@book_path}")
        when %r{^/book/[0-9]+/?$}
          # is_book (/book/:book_id)
          @book_path = Pathname(path_str).split.last.to_s
          @is_book = true
          Logger.debug("#{path_str} is a book: #{@book_path}")
        else
          # is_root
          if ['/book', '/book/'].include? (path_str)
            # Rails.logger.error "is_root = TRUE"
            @is_root = true
            Logger.debug("#{path_str} is the root !")
          else
            Logger.debug("WTF ??? #{path_str}")
          end
        end
        # Rails.logger.error "is_contact = #{@is_card}; is_book = #{@is_book}; is_root = #{@is_root}"
      end
    end
    
  end
end
