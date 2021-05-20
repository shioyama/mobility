# frozen_string_literal: true
require_relative "./active_record/backend"
require_relative "./active_record/dirty"
require_relative "./active_record/cache"
require_relative "./active_record/query"
require_relative "./active_record/uniqueness_validation"
require_relative "./active_record/original_column"

module Mobility
=begin

Plugin for ActiveRecord models. This plugin automatically requires activerecord
related plugins, which are not actually "active" unless their base plugin (e.g.
dirty for active_record_dirty) is also enabled.

=end
  module Plugins
    module ActiveRecord
      extend Plugin

      requires :arel

      requires :active_record_backend, include: :after
      requires :active_record_dirty
      requires :active_record_cache
      requires :active_record_query
      requires :active_record_uniqueness_validation
      requires :active_record_original_column


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
