# frozen-string-literal: true

module Mobility
  module Plugins
    module Reader
=begin

Defines attribute reader that delegates to +Mobility::Backend#read+.

=end
      extend Plugin

      default true
      requires :backend

      initialize_hook do |*names, **|
        if options[:reader]
          names.each do |name|
            class_eval <<-EOM, __FILE__, __LINE__ + 1
              def #{name}(locale: nil, **options)
                #{Reader.setup_source}
                mobility_backends[:#{name}].read(locale, options)
              end
            EOM
            class_eval <<-EOM, __FILE__, __LINE__ + 1
              def #{name}?(locale: nil, **options)
                #{Reader.setup_source}
                mobility_backends[:#{name}].present?(locale, options)
              end
            EOM
          end
        end
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
