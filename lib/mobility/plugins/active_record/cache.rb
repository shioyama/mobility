# frozen-string-literal: true
require "mobility/plugins/active_model/cache"

module Mobility
  module Plugins
    module ActiveRecord
=begin

Resets cache on calls to +reload+, in addition to other AM dirty reset
methods.

=end
      module Cache
        extend Plugin

        depends_on :cache, include: false

        included_hook do |klass, _|
          if options[:cache]
            define_cache_hooks(klass, :changes_applied, :clear_changes_information, :reload)
          end
        end
      end
    end

    register_plugin(:active_record_cache, ActiveRecord::Cache)
  end
end
