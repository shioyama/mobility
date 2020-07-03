# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Defines convenience methods for accessing backends, of the form
"<name>_backend". The format for this method can be customized by passing a
different format string as the plugin option.

=end
    module BackendReader
      extend Plugin

      depends_on :backend

      initialize_hook do |*names, backend_reader: "%s_backend"|
        names.each { |name| define_backend(name, backend_reader) } if backend_reader
      end

      private

      def define_backend(attribute, format_string)
        module_eval <<-EOM, __FILE__, __LINE__ + 1
        def #{format_string % attribute}
          mobility_backends[:#{attribute}]
        end
        EOM
      end
    end

    register_plugin(:backend_reader, BackendReader)
  end
end
