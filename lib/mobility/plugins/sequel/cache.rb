# frozen-string-literal: true

module Mobility
  module Plugins
    module Sequel
=begin

Adds hook to clear Mobility cache when +refresh+ is called on Sequel model.

=end
      module Cache
        extend Plugin

        depends_on :cache, include: false

        included_hook do |klass|
          define_cache_hooks(klass, :refresh) if options[:cache]
        end
      end
    end

    register_plugin(:sequel_cache, Sequel::Cache)
  end
end
