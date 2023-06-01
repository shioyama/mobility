require 'mobility/backends/sequel/db_hash'

Sequel.extension :pg_hstore, :pg_hstore_ops

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Hstore} backend for Sequel models.

@see Mobility::Backends::HashValued

=end
    module Sequel
      class Hstore < DbHash
        # @!group Backend Accessors
        # @!macro backend_reader
        # @!method read(locale, options = {})

        # @!group Backend Accessors
        # @!macro backend_writer
        def write(locale, value, options = {})
          super(locale, value && value.to_s, **options)
        end
        # @!endgroup

        # @param [Symbol] name Attribute name
        # @param [Symbol] locale Locale
        # @return [Mobility::Backends::Sequel::Hstore::HStoreOp]
        def self.build_op(attr, locale)
          column_name = column_affix % attr
          HStoreOp.new(column_name.to_sym)[locale.to_s]
        end

        class HStoreOp < ::Sequel::Postgres::HStoreOp; end
      end
    end

    register_backend(:sequel_hstore, Sequel::Hstore)
  end
end
