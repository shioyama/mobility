require "mobility/arel"
require_relative "./active_record/backend"
require_relative "./active_record/dirty"
require_relative "./active_record/cache"
require_relative "./active_record/query"
require_relative "./active_record/uniqueness_validation"

module Mobility
=begin

Plugin for ActiveRecord models.

=end
  module Plugins
    module ActiveRecord
      extend Plugin

      depends_on :active_record_backend, include: :after
      depends_on :active_record_dirty
      depends_on :active_record_cache
      depends_on :active_record_query
      depends_on :active_record_uniqueness_validation

      included_hook do |klass|
        unless active_record_class?(klass)
          name = klass.name || klass.to_s
          raise TypeError, "#{name} should be a subclass of ActiveRecord::Base to use the active_record plugin"
        end
      end

      private

      def active_record_class?(klass)
        klass < ::ActiveRecord::Base
      end
    end

    register_plugin(:active_record, ActiveRecord)
  end
end
