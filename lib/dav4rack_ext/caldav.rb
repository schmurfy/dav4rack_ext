require 'dav4rack'

require_relative 'handler'
require_relative 'helpers/properties'

require_relative 'caldav/controller'
require_relative 'caldav/resource'
require_relative 'caldav/resources/principal_resource'
require_relative 'caldav/resources/calendar_collection_resource'
require_relative 'caldav/resources/calendar_resource'
require_relative 'caldav/resources/event_resource'

require_relative 'caldav/app'
