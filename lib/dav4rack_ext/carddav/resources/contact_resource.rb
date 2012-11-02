require 'vcard_parser'

module DAV4Rack
  module Carddav
    
    class ContactResource < AddressbookBaseResource
      
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
          Mime::Type.lookup_by_extension(:vcf).to_s
        end

        property('getlastmodified') do
          @contact.updated_at
        end
      end
      
      define_properties('urn:ietf:params:xml:ns:carddav') do
        property('address-data') do
          # if fields.empty?
            data = @contact.vcard.vcard
          # else
            # raise "unsupported"
            
            # data = %w(BEGIN:VCARD)
            # fields.each do |f|
            #   next if f[:name] != 'prop'
            #   name = f[:attributes]['name']
            #   case name.upcase
            #   when 'VERSION'
            #     data << 'VERSION:3.0'
            #   when 'UID'
            #     data << 'UID:%s' % @contact.uid
            #   else
            #     field = @contact.vcard.field(name)
            #     data << field.to_s.strip unless field.nil?
            #   end
            # end
            # data << 'END:VCARD'
            # data = data.compact.join("\n")
          # end
          
          <<-EOS
          <C:address-data xmlns:C="urn:ietf:params:xml:ns:carddav">
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
        current_user.find_contact(File.split(public_path).last) != nil
      end
      
      def setup
        super

        path_str = @public_path.dup
        @address_book = current_user.find_addressbook(@book_path)

        # uid = File.split(path_str).last
        uid = File.basename(path_str, '.vcf')
        # if uid.end_with?('.vcf')
        #   @book_path.slice!(0..-5)
        # end

        @contact = @address_book.find_contact(uid)
        # raise "Unable to find contact with #{uid}" unless @contact
        
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
        raise BadRequest if uid =~ /\./ # Yeah, this'll break our routes.

        # Check for If-None-Match: *
        # Section: 6.3.2
        # If set, client does not want to clobber; error if contact present
        want_new_contact = (request.env['HTTP_IF_NONE_MATCH'] == '*')
        
        @contact = current_user.find_contact(uid)
        p @contact

        # If the client has explicitly stated they want a new contact
        raise Conflict if (want_new_contact and @contact)
        
        if @contact
          Logger.debug("Updating contact #{uid} (#{@contact.object_id})")
        else
          Logger.debug("Creating new contact ! (#{uid})")
          @contact = @address_book.create_contact(uid)
        end

        # Otherwise let's update it
        @contact.update_from_vcard(vcf)

        if @contact.save
          @public_path = "/book/#{@address_book.id}/#{@contact.uid}"
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
        AddressbookResource.new(elements.first, elements.first, @request, @response, @options.merge(:user => @user))
      end
      
      def get(request, response)
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
