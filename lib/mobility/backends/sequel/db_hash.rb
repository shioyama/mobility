# frozen_string_literal: true
require "mobility/util"
require "mobility/backends/sequel"
require "mobility/backends/hash_valued"

module Mobility
  module Backends
=begin

Internal class used by Sequel backends backed by a Postgres data type (hstore,
jsonb).

=end
    module Sequel
      class DbHash
        include Sequel
        include HashValued

        def read(locale, options = {})
          super(locale.to_s, options)
        end

        def write(locale, value, options = {})
          super(locale.to_s, value, options)
        end

        # @!macro backend_iterator
        def each_locale
          super { |l| yield l.to_sym }
        end

        def translations
          model[column_name.to_sym]
        end

        setup do |attributes, options, backend_class|
          columns = attributes.map { |attribute| (options[:column_affix] % attribute).to_sym }

          mod = Module.new do
            define_method :before_validation do
              columns.each do |column|
                self[column].delete_if { |_, v| v.nil? }
              end
              super()
            end
          end
          include mod
          backend_class.define_hash_initializer(mod, columns)
          backend_class.define_column_changes(mod, attributes, column_affix: options[:column_affix])

          plugin :defaults_setter
          columns.each { |column| default_values[column] = {} }
        end
      end
      private_constant :DbHash
    end
  end
end
