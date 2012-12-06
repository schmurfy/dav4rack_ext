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
        explicit do
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
      end
      
      

      def collection?
        false
      end

      def exist?
        Logger.info "ContactR::exist?(#{public_path});"
        @contact != nil
      end
      
      def setup
        super
        
        @address_book = @options[:_parent_] || current_user.current_addressbook()
        @contact = @options[:_object_] || current_user.current_contact()
        
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
          response['ETag'] = @contact.etag
          Created
        else
          # Mac OS X Contact will reload the contact
          # from the server
          raise Forbidden
        end
      end

      def parent
        @address_book
      end
      
      def parent_exists?
        @address_book != nil
      end
      
      def parent_collection?
        true
      end
      
      def get(request, response)
        response.headers['Etag'] = @contact.etag
        response.body = @contact.vcard.vcard
      end

      def delete
        @contact.destroy
        NoContent
      end

    end
    
  end
end
