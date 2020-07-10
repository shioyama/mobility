# frozen-string-literal: true

module Mobility
  module Plugins
    module ActiveModel
=begin

Adds hooks to clear Mobility cache when AM dirty reset methods are called.

=end
      module Cache
        extend Plugin

        depends_on :cache, include: false

        included_hook do |klass, _|
          if options[:cache]
            define_cache_hooks(klass, :changes_applied, :clear_changes_information)
          end
        end
      end
    end

    register_plugin(:active_model_cache, ActiveModel::Cache)
  end
end
