require 'vcard_parser'

module DAV4Rack
  module Carddav
    
    class ContactResource < Resource
      
      define_properties('DAV:') do
        property('getetag') do
          @contact.etag
        end
        
        property('creationdate') do
          @contact.created_at
        end

        property('getcontentlength') do
          @contact.vcard.to_s.size
        end

        property('getcontenttype') do
          "text/vcard"
        end

        property('getlastmodified') do
          @contact.updated_at
        end
      end
      
      define_properties(CARDAV_NS) do
        property('address-data') do |el|
          
          fields = el[:children].select{|e| e[:name] == 'prop' }.map{|e| e[:attributes]['name'] }
          data = @contact.vcard.to_s(fields)
                    
          <<-EOS
          <C:address-data xmlns:C="#{CARDAV_NS}">
            <![CDATA[#{data}]]>
          </C:address-data>
          EOS
        end
      end
      
      

      def collection?
        false
      end

      def exist?
        Logger.info "ContactR::exist?(#{public_path});"
        @contact != nil
        # current_user.find_contact(File.split(public_path).last) != nil
      end
      
      def setup
        super
        
        @address_book = options[:_parent_] || current_user.find_addressbook(router_params)
        @contact = options[:_object_] || @address_book.find_contact(router_params[:contact_id])
        
      end

      def put(request, response)
        b = request.body.read

        # Ensure we only have one vcard per request
        # Section 5.1:
        # Address object resources contained in address book collections MUST
        # contain a single vCard component only.
        vcards = VCardParser::VCard.parse(b)
        raise BadRequest if vcards.size != 1
        vcf = vcards[0]

        uid = vcf['UID'].value

        # [6.3.2] Check for If-None-Match: *
        # If set, client does want to create a new contact only, raise an error
        # if contact already exists
        want_new_contact = (request.env['HTTP_IF_NONE_MATCH'] == '*')
        
        @contact = @address_book.find_contact(uid)

        # If the client has explicitly stated they want a new contact
        raise Conflict if (want_new_contact and @contact)
        
        if @contact
          Logger.debug("Updating contact #{uid} (#{@contact.object_id})")
        else
          Logger.debug("Creating new contact ! (#{uid})")
          @contact = @address_book.create_contact(uid)
        end

        @contact.update_from_vcard(vcf)

        if @contact.save
          @public_path = File.join(@address_book.path, @contact.uid)
          # @public_path = "/book/#{@address_book.id}/#{@contact.uid}"
          response['ETag'] = @contact.etag
          Created
        else
          # Is another error more appropriate?
          raise Conflict
        end
      end

      # Overload parent in this case because we want a different class (AddressBookResource)
      def parent
        # Rails.logger.error "Contact::Parent FOR: #{@public_path}"
        elements = File.split(@public_path)
        return nil if (elements.first == '/book')
        AddressbookResource.new(elements.first, elements.first, @request, @response, @options)
      end
      
      def get(request, response)
        response.headers['Etag'] = @contact.etag
        response.body = @contact.vcard.vcard
      end

      def delete
        # TODO: Proper authorization, is this OUR contact?
        @contact.destroy
        NoContent
      end

    end
    
  end
end
