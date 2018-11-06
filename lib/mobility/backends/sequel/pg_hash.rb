# frozen_string_literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/hash_valued"
require "mobility/sequel/column_changes"
require "mobility/sequel/hash_initializer"

module Mobility
  module Backends
=begin

Internal class used by Sequel backends backed by a Postgres data type (hstore,
jsonb).

=end
    module Sequel
      class PgHash
        include Sequel
        include HashValued

        def read(locale, options = {})
          [locale, super(locale.to_s, options)[1]]
        end

        def write(locale, value, options = {})
          [locale, super(locale.to_s, value, options)[1]]
        end

        # @!macro backend_iterator
        def each_locale
          super { |l| yield l.to_sym }
        end

        def translations
          model[column_name.to_sym]
        end

        setup do |attributes, options|
          columns = attributes.map { |attribute| (options[:column_affix] % attribute).to_sym }

          before_validation = Module.new do
            define_method :before_validation do
              columns.each do |column|
                self[column].delete_if { |_, v| Util.blank?(v) }
              end
              super()
            end
          end
          include before_validation
          include Mobility::Sequel::HashInitializer.new(*columns)
          include Mobility::Sequel::ColumnChanges.new(attributes, column_affix: options[:column_affix])

          plugin :defaults_setter
          columns.each { |column| default_values[column] = {} }
        end
      end
      private_constant :PgHash
    end
  end
end
