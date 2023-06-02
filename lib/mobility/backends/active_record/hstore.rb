require 'mobility/backends/active_record/db_hash'
require 'mobility/plugins/arel/nodes/pg_ops'

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Hstore} backend for ActiveRecord models.

@see Mobility::Backends::HashValued

=end
    module ActiveRecord
      class Hstore < DbHash
        # @!group Backend Accessors
        # @!macro backend_reader
        # @!method read(locale, options = {})

        # @!macro backend_writer
        def write(locale, value, options = {})
          super(locale, value && value.to_s, **options)
        end
        # @!endgroup

        # @param [String] attr Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Plugins::Arel::Nodes::Hstore] Arel node for value of
        #   attribute key on hstore column
        def self.build_node(attr, locale)
          column_name = column_affix % attr
          Plugins::Arel::Nodes::Hstore.new(model_class.arel_table[column_name], build_quoted(locale))
        end
      end
    end

    register_backend(:active_record_hstore, ActiveRecord::Hstore)
  end
end
