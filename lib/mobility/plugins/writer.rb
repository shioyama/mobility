# frozen-string-literal: true

module Mobility
  module Plugins
    module Writer
=begin

Defines attribute writer that delegates to +Mobility::Backend#write+.

=end
      TYPES_MAP  = { String => :string, Integer => :integer, Float => :float,
                     TrueClass => :bool, FalseClass => :bool, Array => :array, Hash => :hash }

      extend Plugin

      default true
      requires :backend

      initialize_hook do |*names|
        if options[:writer]
          type_option = options[:writer][:type] if options[:writer].is_a?(Hash)

          names.each do |name|
            class_eval <<-EOM, __FILE__, __LINE__ + 1
              def #{name}=(value, locale: nil, **options)
                #{Writer.check_type(name, type_option) if type_option}
                #{Writer.setup_source}
                mobility_backends[:#{name}].write(locale, value, **options)
              end
            EOM
          end
        end
      end

      class TypeError < StandardError; end

      def self.check_type(name, type)
        <<-EOL
        if !value.nil? 
          value_type = #{TYPES_MAP}[value.class]
          if value_type != :#{type}        
            raise Mobility::Plugins::Writer::TypeError, "#{name}= called with \#{value_type}, #{type} expected"
          end
        end
        EOL
      end

      def self.setup_source
        <<-EOL
        return super(value) if options[:super]
        if (locale &&= locale.to_sym)
          #{"Mobility.enforce_available_locales!(locale)" if I18n.enforce_available_locales}
          options[:locale] = true
        else
          locale = Mobility.locale
        end
        EOL
      end
    end

    register_plugin(:writer, Writer)
  end
end
