# frozen_string_literal: true
require "mobility/backends/active_record"
require "mobility/backends/hash_valued"

module Mobility
  module Backends
=begin

Internal class used by ActiveRecord backends backed by a Postgres data type
(hstore, jsonb).

=end
    module ActiveRecord
      class PgHash
        include ActiveRecord
        include HashValued

        # @!macro backend_iterator
        def each_locale
          super { |l| yield l.to_sym }
        end

        def translations
          model.read_attribute(column_name)
        end

        setup do |attributes, options = {}|
          attributes.each { |attribute| store (options[:column_affix] % attribute), coder: Coder }
        end

        class Coder
          def self.dump(obj)
            if obj.is_a? ::Hash
              obj.inject({}) do |translations, (locale, value)|
                translations[locale] = value if value.present?
                translations
              end
            else
              raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
            end
          end

          def self.load(obj)
            obj
          end
        end
      end
      private_constant :PgHash
    end
  end
end
