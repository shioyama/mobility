# frozen-string-literal: true

module Mobility
  module Plugins
    module Reader
=begin

Defines attribute reader that delegates to +Mobility::Backend#read+.

=end
      extend Plugin

      depends_on :backend

      initialize_hook do |*names, reader: true|
        names.each { |name| define_reader(name) } if reader
      end

      private

      def define_reader(attribute)
        class_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{attribute}(locale: nil, **options)
            #{Reader.setup_source}
            mobility_backends[:#{attribute}].read(locale, options)
          end
        EOM
        class_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{attribute}?(locale: nil, **options)
            #{Reader.setup_source}
            mobility_backends[:#{attribute}].present?(locale, options)
          end
        EOM
      end

      def self.setup_source
        <<-EOL
        return super() if options[:super]
        if (locale &&= locale.to_sym)
          #{"Mobility.enforce_available_locales!(locale)" if I18n.enforce_available_locales}
          options[:locale] = true
        else
          locale = Mobility.locale
        end
        EOL
      end
    end

    register_plugin(:reader, Reader)
  end
end
