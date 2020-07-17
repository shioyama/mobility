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

      default true
      depends_on :backend

      initialize_hook do |*names|
        backend_reader = options[:backend_reader]
        backend_reader = "%s_backend" if backend_reader == true
        if backend_reader
          names.each do |name|
            module_eval <<-EOM, __FILE__, __LINE__ + 1
            def #{backend_reader % name}
              mobility_backends[:#{name}]
            end
            EOM
          end
        end
      end
    end

    register_plugin(:backend_reader, BackendReader)
  end
end
