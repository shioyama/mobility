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
      class DbHash
        include ActiveRecord
        include HashValued

        def read(locale, _options = nil)
          translations[locale.to_s]
        end

        def write(locale, value, _options = nil)
          if value.nil?
            translations.delete(locale.to_s)
          else
            translations[locale.to_s] = value
          end
        end

        # @!macro backend_iterator
        def each_locale
          super { |l| yield l.to_sym }
        end

        def translations
          model[column_name] ||= {}
          model[column_name]
        end
      end
      private_constant :DbHash
    end
  end
end
