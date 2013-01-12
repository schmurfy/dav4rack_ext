module Helpers
  module Properties
    class MethodMissingRedirector
      def initialize(*methods, &block)
        @block = block
        @methods = methods
      end

      def method_missing(name, *args, &block)
        if @methods.empty? || @methods.include?(name)
          @block.call(name, *args, &block)
        end
      end
    end

    def self.extended(klass)
      class << klass
        include MetaClassMethods
      end
    end

    # inheritable accessor
    module MetaClassMethods
      def define_property(namespace, name, explicit = false, &block)
        _properties["#{namespace}*#{name}"] = [block, explicit]
      end

      def properties
        inherited = superclass.respond_to?(:properties) ? superclass.properties : {}
        inherited.merge(_properties)
      end

      def _properties
        @properties ||= {}
      end
    end

    def define_properties(namespace, &block)
      explicit = false
      obj = MethodMissingRedirector.new(:property, :explicit) do |method_name, name, &block|
        if method_name == :property
          define_property(namespace, name.to_s, explicit, &block)
        elsif method_name == :explicit
          explicit = true
          block.call
        else
          raise NoMethodError, method_name
        end
      end

      obj.instance_eval(&block)
    end

  end
end
