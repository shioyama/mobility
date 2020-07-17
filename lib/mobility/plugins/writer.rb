# frozen-string-literal: true

module Mobility
  module Plugins
    module Writer
=begin

Defines attribute writer that delegates to +Mobility::Backend#write+.

=end
      extend Plugin

      default true
      depends_on :backend

      initialize_hook do |*names|
        if options[:writer]
          names.each do |name|
            class_eval <<-EOM, __FILE__, __LINE__ + 1
              def #{name}=(value, locale: nil, **options)
                #{Writer.setup_source}
                mobility_backends[:#{name}].write(locale, value, options)
              end
            EOM
          end
        end
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
