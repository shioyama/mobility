# frozen_string_literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/hash_valued"
require "mobility/backend/stringify_locale"
require "mobility/sequel/column_changes"

module Mobility
  module Backends
=begin

Internal class used by Sequel backends backed by a Postgres data type (hstore,
jsonb).

=end
    class Sequel::PgHash
      include Sequel
      include HashValued
      include StringifyLocale

      # @!macro backend_iterator
      def each_locale
        super { |l| yield l.to_sym }
      end

      def translations
        model[attribute.to_sym]
      end

      setup do |attributes|
        before_validation = Module.new do
          define_method :before_validation do
            attributes.each do |attribute|
              self[attribute.to_sym].delete_if { |_, v| Util.blank?(v) }
            end
            super()
          end
        end
        include before_validation
        include Mobility::Sequel::HashInitializer.new(*attributes)
        include Mobility::Sequel::ColumnChanges.new(*attributes)

        plugin :defaults_setter
        attributes.each { |attribute| default_values[attribute.to_sym] = {} }
      end
    end
  end
end
